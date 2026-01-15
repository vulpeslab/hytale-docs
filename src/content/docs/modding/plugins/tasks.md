---
author: UnlimitedBytes
title: Task Scheduling and Async System
description: Schedule and manage asynchronous tasks in your Hytale plugins.
sidebar:
  order: 6
---

The Hytale server provides several mechanisms for scheduling tasks, handling asynchronous operations, and managing work across different execution contexts.

## Architecture Overview

```
HytaleServer
├── SCHEDULED_EXECUTOR      - Global single-threaded ScheduledExecutorService for timed tasks
└── EventBus                - Async event handling

World (extends TickingThread, implements Executor, ExecutorMetricsRegistry.ExecutorMetric)
├── taskQueue               - LinkedBlockingDeque<Runnable> executed on the world thread
├── acceptingTasks          - AtomicBoolean controlling task acceptance
├── tick()                  - Called 30 times per second (configurable TPS)
└── execute()               - Submit tasks to run on the world thread

TickingThread
├── TPS = 30                - Default ticks per second
├── NANOS_IN_ONE_SECOND     - 1,000,000,000 nanoseconds
├── NANOS_IN_ONE_MILLI      - 1,000,000 nanoseconds
└── SLEEP_OFFSET            - 3,000,000 nanoseconds

TaskRegistry (per-plugin)
└── Tracks CompletableFuture<Void> and ScheduledFuture<Void> registrations
```

## Task Registry

Each plugin has access to a `TaskRegistry` through `getTaskRegistry()`. This registry tracks scheduled tasks and ensures they are properly cancelled when the plugin is disabled.

### Registering Tasks

```java
import com.hypixel.hytale.server.core.task.TaskRegistration;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

@Override
protected void setup() {
    // Register a CompletableFuture<Void> task
    CompletableFuture<Void> asyncTask = CompletableFuture.runAsync(() -> {
        // Long-running operation
    });
    TaskRegistration registration = getTaskRegistry().registerTask(asyncTask);

    // Register a ScheduledFuture<Void> task
    ScheduledFuture<Void> scheduledTask = HytaleServer.SCHEDULED_EXECUTOR.schedule(
        () -> { /* task */ return null; },
        5, TimeUnit.SECONDS
    );
    getTaskRegistry().registerTask(scheduledTask);
}
```

### Task Registration

The `TaskRegistration` class wraps a `Future` and provides lifecycle management:

```java
public class TaskRegistration extends Registration {
    private final Future<?> task;

    // Constructor automatically sets up cancellation on unregister
    public TaskRegistration(@Nonnull Future<?> task) {
        super(() -> true, () -> task.cancel(false));
        this.task = task;
    }

    // Copy constructor with custom lifecycle callbacks
    public TaskRegistration(@Nonnull TaskRegistration registration,
                           BooleanSupplier isEnabled, Runnable unregister) {
        super(isEnabled, unregister);
        this.task = registration.task;
    }

    public Future<?> getTask() {
        return this.task;
    }
}
```

Note: The `TaskRegistry.registerTask()` method accepts specifically `CompletableFuture<Void>` or `ScheduledFuture<Void>` - not generic Future types.

When your plugin is disabled or the server shuts down, all registered tasks are automatically cancelled.

## Global Scheduled Executor

The `HytaleServer.SCHEDULED_EXECUTOR` is a single-threaded `ScheduledExecutorService` available for scheduling delayed and repeating tasks:

```java
import com.hypixel.hytale.server.core.HytaleServer;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.ScheduledFuture;

// One-time delayed task
ScheduledFuture<?> delayedTask = HytaleServer.SCHEDULED_EXECUTOR.schedule(
    () -> getLogger().at(Level.INFO).log("Executed after 5 seconds"),
    5, TimeUnit.SECONDS
);

// Repeating task with fixed delay
ScheduledFuture<?> repeatingTask = HytaleServer.SCHEDULED_EXECUTOR.scheduleWithFixedDelay(
    () -> {
        // Runs every 10 seconds after the previous execution completes
        performPeriodicCleanup();
    },
    10, 10, TimeUnit.SECONDS
);

// Repeating task at fixed rate
ScheduledFuture<?> fixedRateTask = HytaleServer.SCHEDULED_EXECUTOR.scheduleAtFixedRate(
    () -> {
        // Runs every 5 seconds regardless of execution time
        sendHeartbeat();
    },
    0, 5, TimeUnit.SECONDS
);
```

:::caution
The scheduled executor runs on a separate thread. If you need to interact with world state or entities, you must dispatch work to the appropriate world thread using `world.execute()`.
:::

## World Thread Execution

Each `World` instance runs on its own dedicated thread and implements `Executor`. Use `world.execute()` to run code on the world thread:

```java
import com.hypixel.hytale.server.core.universe.world.World;
import com.hypixel.hytale.server.core.universe.Universe;
import java.util.concurrent.CompletableFuture;

// Get a world reference (returns null if world doesn't exist)
World world = Universe.get().getWorld("myWorld");

// Execute on the world thread
world.execute(() -> {
    // This runs on the world thread via a LinkedBlockingDeque taskQueue
    // Safe to modify entities, blocks, etc.
});

// Async operation that returns to the world thread
CompletableFuture.supplyAsync(() -> {
    // Heavy computation on ForkJoinPool
    return computeExpensiveValue();
}).thenAcceptAsync(result -> {
    // Process result on the world thread
    applyResultToWorld(result);
}, world);
```

:::note
The `world.execute()` method will throw a `SkipSentryException` wrapping an `IllegalThreadStateException` if the world is no longer accepting tasks (e.g., during shutdown). Always check `world.isAlive()` before submitting tasks to a world that may be shutting down.
:::

### Tick Rate and Timing

Worlds tick at 30 TPS by default. You can adjust this or work with tick-based timing:

```java
// Constants from TickingThread
public static final int NANOS_IN_ONE_MILLI = 1000000;
public static final int NANOS_IN_ONE_SECOND = 1000000000;
public static final int TPS = 30;
public static long SLEEP_OFFSET = 3000000L;

// Get current tick rate
int tps = world.getTps();
int nanosPerTick = world.getTickStepNanos(); // 33,333,333 ns at 30 TPS

// Check if running on the world thread
if (world.isInThread()) {
    // Safe to access world state directly
}

// Set a custom TPS (must be between 1 and 2048, called from world thread)
world.setTps(60);
```

## CompletableFuture Patterns

### Utility Methods

The `CompletableFutureUtil` class provides helpful utilities:

```java
import com.hypixel.hytale.common.util.CompletableFutureUtil;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CancellationException;
import java.util.concurrent.CompletionException;

// Check if a throwable represents cancellation (handles nested CompletionExceptions)
if (CompletableFutureUtil.isCanceled(throwable)) {
    // Handle cancellation gracefully - checks for CancellationException
    // and recursively unwraps CompletionException causes
    return;
}

// Create an already-cancelled future
CompletableFuture<String> cancelled = CompletableFutureUtil.completionCanceled();

// Catch and log unhandled exceptions (logs to severe and wraps in TailedRuntimeException)
CompletableFuture<MyResult> safeFuture = CompletableFutureUtil._catch(myFuture);

// Transfer completion state from one future to another
CompletableFutureUtil.whenComplete(sourceFuture, targetFuture);
```

### Combining Futures

```java
import java.util.concurrent.CompletableFuture;
import java.util.List;

// Wait for all futures
List<CompletableFuture<Void>> tasks = List.of(task1, task2, task3);
CompletableFuture<Void> all = CompletableFuture.allOf(
    tasks.toArray(CompletableFuture[]::new)
);

// Chain operations
CompletableFuture<World> worldFuture = loadConfig()
    .thenCompose(config -> createWorld(config))
    .thenApply(world -> {
        initializeWorld(world);
        return world;
    });

// Handle errors
worldFuture.exceptionally(throwable -> {
    getLogger().at(Level.SEVERE).log("Failed to create world: " + throwable.getMessage());
    return null;
});
```

## Async Commands

For commands that perform long-running operations, extend `AbstractAsyncCommand`:

```java
import com.hypixel.hytale.server.core.command.system.basecommands.AbstractAsyncCommand;
import com.hypixel.hytale.server.core.command.system.CommandContext;
import com.hypixel.hytale.server.core.Message;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ForkJoinPool;

public class MyAsyncCommand extends AbstractAsyncCommand {

    public MyAsyncCommand() {
        // Available constructors:
        // super(String name, String description)
        // super(String name, String description, boolean requiresConfirmation)
        // super(String description) - name derived from class name
        super("mycommand", "Performs an async operation");
    }

    @Override
    @Nonnull
    protected CompletableFuture<Void> executeAsync(@Nonnull CommandContext context) {
        // runAsync wraps the runnable in try-catch, logging exceptions
        // and sending MESSAGE_MODULES_COMMAND_RUNTIME_ERROR to context
        return runAsync(context, () -> {
            // Long-running operation
            performHeavyComputation();
            context.sendMessage(Message.text("Operation complete!"));
        }, ForkJoinPool.commonPool());
    }
}
```

## Common Scheduling Patterns

### Periodic Tasks

```java
@Override
protected void start() {
    int frequencyMinutes = config.get().getBackupFrequency();

    // Note: scheduleWithFixedDelay returns ScheduledFuture<?>, but registerTask
    // expects ScheduledFuture<Void>. You can either cast or use Callable<Void>.
    @SuppressWarnings("unchecked")
    ScheduledFuture<Void> backupTask = (ScheduledFuture<Void>) HytaleServer.SCHEDULED_EXECUTOR.scheduleWithFixedDelay(
        () -> {
            try {
                getLogger().at(Level.INFO).log("Starting scheduled backup...");
                performBackup().thenAccept(v ->
                    getLogger().at(Level.INFO).log("Backup completed successfully")
                );
            } catch (Exception e) {
                getLogger().at(Level.SEVERE).log("Backup failed: " + e.getMessage());
            }
        },
        frequencyMinutes,
        frequencyMinutes,
        TimeUnit.MINUTES
    );

    getTaskRegistry().registerTask(backupTask);
}
```

### Delayed Player Actions

```java
// Schedule a timeout for player response using Callable<Void> to get ScheduledFuture<Void>
ScheduledFuture<Void> timeout = HytaleServer.SCHEDULED_EXECUTOR.schedule(
    () -> { handleTimeout(player); return null; },
    10, TimeUnit.SECONDS
);

// Cancel if player responds in time
void onPlayerResponse(PlayerRef player) {
    timeout.cancel(false);
    processResponse(player);
}
```

### Batched Processing

```java
// Process items in batches across multiple ticks
public CompletableFuture<Void> processInBatches(World world, List<Item> items, int batchSize) {
    CompletableFuture<Void> result = new CompletableFuture<>();
    processNextBatch(world, items, 0, batchSize, result);
    return result;
}

private void processNextBatch(World world, List<Item> items, int offset,
                              int batchSize, CompletableFuture<Void> result) {
    world.execute(() -> {
        int end = Math.min(offset + batchSize, items.size());
        for (int i = offset; i < end; i++) {
            processItem(items.get(i));
        }

        if (end < items.size()) {
            // Schedule next batch for next tick
            world.execute(() ->
                processNextBatch(world, items, end, batchSize, result)
            );
        } else {
            result.complete(null);
        }
    });
}
```

### Cross-Thread Data Transfer

```java
// Load data async, then apply on world thread
public CompletableFuture<Void> loadAndApplyData(World world, String dataId) {
    return CompletableFuture.supplyAsync(() -> {
        // Heavy I/O on background thread
        return loadDataFromDisk(dataId);
    }).thenAcceptAsync(data -> {
        // Apply data on world thread
        applyDataToWorld(world, data);
    }, world);
}
```

## Task Cancellation and Cleanup

### Manual Cancellation

```java
// Store reference for later cancellation
private ScheduledFuture<Void> myTask;

@Override
protected void start() {
    // scheduleWithFixedDelay returns ScheduledFuture<?>, cast to ScheduledFuture<Void>
    @SuppressWarnings("unchecked")
    ScheduledFuture<Void> task = (ScheduledFuture<Void>) HytaleServer.SCHEDULED_EXECUTOR.scheduleWithFixedDelay(
        this::periodicWork,
        1, 1, TimeUnit.MINUTES
    );
    myTask = task;
    getTaskRegistry().registerTask(myTask);
}

public void cancelTask() {
    if (myTask != null && !myTask.isDone()) {
        myTask.cancel(false);  // false = don't interrupt if running
    }
}
```

### Automatic Cleanup

The `TaskRegistry` automatically cancels all registered tasks when your plugin is disabled.

## Best Practices

1. **Register scheduled tasks** - Always register long-running or repeating tasks with `getTaskRegistry()` for automatic cleanup.

2. **Use the right executor** - Use `HytaleServer.SCHEDULED_EXECUTOR` for timed tasks, `world.execute()` for world thread work, and `CompletableFuture.supplyAsync()` for background computation.

3. **Handle exceptions** - Always handle exceptions in async code to prevent silent failures:
   ```java
   future.exceptionally(throwable -> {
       getLogger().at(Level.SEVERE).log("Task failed: " + throwable.getMessage());
       return null;
   });
   ```

4. **Respect thread safety** - World state (entities, blocks, chunks) should only be modified on the world thread.

5. **Avoid blocking** - Never block the world thread with `future.join()` or `Thread.sleep()`. Use async chaining instead.

6. **Cancel unused tasks** - Cancel scheduled tasks when they're no longer needed to prevent resource leaks.

7. **Use appropriate timeouts** - Add timeouts to futures that might hang:
   ```java
   future.orTimeout(30, TimeUnit.SECONDS)
       .exceptionally(e -> {
           if (e instanceof TimeoutException) {
               getLogger().at(Level.WARNING).log("Operation timed out");
           }
           return null;
       });
   ```

8. **Batch large operations** - When processing many items, split work across multiple ticks to avoid lag spikes.
