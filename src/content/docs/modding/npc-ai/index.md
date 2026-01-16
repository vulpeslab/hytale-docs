---
author: UnlimitedBytes
title: NPC & AI System
description: Overview of Hytale's NPC and AI systems for creating intelligent entities
human-verified: false
---

The NPC & AI system in Hytale provides a comprehensive framework for creating intelligent non-player characters with complex behaviors, decision-making capabilities, and interactions. The system is built on several interconnected components that work together to create believable AI behaviors.

## Core Components

The NPC system is implemented through the `NPCPlugin` and consists of several major subsystems:

- **Blackboard System** - Shared memory system for AI decision-making
- **Decision Makers** - State evaluation and condition-based logic
- **Instructions** - Behavioral building blocks (sensors, actions, motions)
- **Roles** - High-level NPC behavior definitions
- **Navigation & Pathfinding** - A* pathfinding and movement
- **Animations** - Animation state management

## NPCPlugin

The `NPCPlugin` class (`com.hypixel.hytale.server.npc.NPCPlugin`) serves as the central registration and management point for all NPC-related functionality. It:

- Registers NPC entity types and components
- Manages the blackboard resource system
- Registers core component builders for NPC behaviors
- Coordinates with the spawning and flock systems
- Handles NPC lifecycle events

## Key Classes

### NPCEntity

`NPCEntity` is the base component type for all NPCs in the game. It extends the standard entity system and adds:

- Role management
- Instruction execution
- Movement and steering
- Combat capabilities
- Interaction handling

### Role

The `Role` class (`com.hypixel.hytale.server.npc.role.Role`) defines the complete behavior set for an NPC, including:

- Instructions and state machines
- Motion controllers
- Combat parameters
- Item handling (hotbar, inventory)
- Environmental constraints
- Flock behavior settings

Roles contain support objects for various systems:
- `CombatSupport` - Combat-related functionality
- `StateSupport` - State machine management
- `EntitySupport` - Entity tracking and targeting
- `WorldSupport` - World interaction
- `PositionCache` - Cached position data for performance

## Component Types

NPCs use the ECS (Entity Component System) architecture with various component types:

- `StepComponent` - Tracks current instruction step
- `Timers` - Manages NPC-specific timers
- `SpawnBeaconReference` - Links NPCs to their spawn beacons
- `SpawnMarkerReference` - Links NPCs to spawn markers
- `FailedSpawnComponent` - Tracks spawn failures

## Systems

The NPC plugin registers several systems for managing NPC behavior:

- Instruction execution systems
- Navigation and pathfinding systems
- Animation systems
- Combat systems
- Interaction systems
- Reference management systems

## Asset Integration

NPCs are defined through asset files that specify:

- NPC configurations (models, stats, behaviors)
- Role definitions
- Instruction sets
- State transitions
- Item loadouts

Assets are loaded via the `HytaleAssetStore` and validated through builder patterns.

## Related Systems

The NPC system integrates with:

- [Spawning System](/modding/spawning) - Controls NPC spawning
- [Flock System](/modding/flock) - Manages group behaviors
- Entity Stats - Health, damage, and stat management
- Inventory System - Item handling for NPCs
- Interaction System - Player-NPC interactions

## Next Steps

Explore the subsystems in detail:

- [Blackboard System](/modding/npc-ai/blackboard) - Shared AI memory
- [Decision Makers](/modding/npc-ai/decision-makers) - State evaluation
- [Instructions](/modding/npc-ai/instructions) - Behavioral components
- [Navigation](/modding/npc-ai/navigation) - Pathfinding and movement
- [Roles](/modding/npc-ai/roles) - NPC behavior definitions
- [Animations](/modding/npc-ai/animations) - Animation management
