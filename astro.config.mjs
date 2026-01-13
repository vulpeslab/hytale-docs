// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	integrations: [
		starlight({
			title: 'Hytale Server Docs (Unofficial)',
			description: 'Unofficial community documentation for running and modding Hytale servers',
			defaultLocale: 'en',
			customCss: ['./src/styles/custom.css'],
			social: [
				{ icon: 'github', label: 'GitHub', href: 'https://github.com/vulpeslab/hytale-docs' },
				{ icon: 'discord', label: 'Discord', href: 'https://discord.gg/jshWA2kRmF' },
			],
			sidebar: [
				{
					label: 'Getting Started',
					items: [
						{ label: 'Getting Started', slug: 'getting-started/introduction' },
						{ label: 'Installation', slug: 'getting-started/installation' },
						{ label: 'Server Configuration', slug: 'getting-started/project-setup' },
					],
				},
				{
					label: 'Modding',
					items: [
						{ label: 'Overview', slug: 'modding/overview' },
						{ label: 'Plugin System', slug: 'modding/plugin-system' },
						{ label: 'Event System', slug: 'modding/events' },
						{ label: 'Component System (ECS)', slug: 'modding/components' },
						{ label: 'Commands', slug: 'modding/commands' },
						{ label: 'Networking', slug: 'modding/networking' },
						{ label: 'Assets & Registry', slug: 'modding/assets' },
						{ label: 'Physics', slug: 'modding/physics' },
						{ label: 'Entity Stats', slug: 'modding/entity-stats' },
						{ label: 'World Generation', slug: 'modding/world-generation' },
						{ label: 'Player Persistence', slug: 'modding/player-persistence' },
						{ label: 'Inventory & Items', slug: 'modding/inventory' },
						{ label: 'Permissions', slug: 'modding/permissions' },
						{ label: 'Task Scheduling', slug: 'modding/tasks' },
						{ label: 'Prefabs', slug: 'modding/prefabs' },
						{ label: 'GUI Overview', slug: 'modding/gui-overview' },
						{ label: 'GUI Windows', slug: 'modding/gui-windows' },
						{ label: 'GUI Custom Pages', slug: 'modding/gui-pages' },
						{ label: 'GUI HUD System', slug: 'modding/gui-hud' },
						{ label: 'Examples', slug: 'modding/examples' },
					],
				},
			],
			head: [
				{
					tag: 'meta',
					attrs: {
						name: 'theme-color',
						content: '#ff9900',
					},
				},
			],
		}),
	],
});
