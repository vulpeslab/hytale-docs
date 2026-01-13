# Hytale Server Documentation (Unofficial)

[![Built with Starlight](https://astro.badg.es/v2/built-with-starlight/tiny.svg)](https://starlight.astro.build)

Unofficial community documentation for running and modding Hytale dedicated servers. This documentation was created through decompilation and analysis of the HytaleServer.jar.

## 📖 Documentation Topics

- **Getting Started** — Installation, project setup, and server configuration
- **Plugin System** — Plugin architecture, lifecycle, and manifest format
- **Event System** — Subscribing to and creating custom events
- **Component System (ECS)** — Entity-Component-System architecture
- **Commands** — Creating custom server commands
- **Networking** — Protocol and packet handling
- **Assets & Registry** — Custom content registration
- **World Generation** — Terrain and structure generation
- **And more...**

## 🚀 Project Structure

```
.
├── public/              # Static assets (favicon, etc.)
├── src/
│   ├── assets/          # Images and media
│   ├── content/
│   │   └── docs/        # Documentation pages
│   │       ├── getting-started/
│   │       └── modding/
│   └── styles/          # Custom CSS
├── decompiled/          # Decompiled source reference
├── astro.config.mjs     # Astro + Starlight config
└── package.json
```

## 🧞 Commands

| Command           | Action                                      |
| :---------------- | :------------------------------------------ |
| `npm install`     | Install dependencies                        |
| `npm run dev`     | Start local dev server at `localhost:4321`  |
| `npm run build`   | Build production site to `./dist/`          |
| `npm run preview` | Preview build locally before deploying      |

## 🤝 Contributing

Contributions are welcome! If you have additional information about the Hytale server API or find errors in the documentation:

1. Fork the repository
2. Create a feature branch
3. Add or update documentation in `src/content/docs/`
4. Submit a pull request

## 🔗 Links

- [GitHub Repository](https://github.com/vulpeslab/hytale-docs)
- [Discord Community](https://discord.gg/jshWA2kRmF)

## ⚠️ Disclaimer

This is unofficial community documentation created through reverse engineering. It is not affiliated with or endorsed by Hypixel Studios. Implementation details may change in future Hytale versions.
