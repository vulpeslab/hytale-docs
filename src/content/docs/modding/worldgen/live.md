---
author: Xaphedo
title: Setting Up Live Worldgen Editing 
description: Step-by-step instructions on how to set up a dedicated instace to edit v2 worldgen and see the results update in game, in real time
sidebar:
  order: 5
human-verified: false
---

:::caution
This is a result of *extremely* early v2 worldgen testing, so this tutorial might be doing too much / not enough compared to what the official v2 docs will reccomend. Be aware, the savefile can be permanently ruined by this. Only try on a fresh world that you don't mind throwing away.
:::

In short, in this tutorial we'll be creating a "directory asset pack" that allows to create a new instance with a custom biome, mirroring the file structure found in the `Zone1_Plains1` Instance/WorldStructure and the `Plains1_River` biome and making some adjustments so it's only one biome. Then we will load up the new instance and use the `/viewport` command to make any edits we make appear in-game, live.

## Step-by-step instructions

### 1. Creating the asset pack
Create a new creative world and go to Creative Tools: press `B`; make sure you press `-` and type `/op self` to enable all permissions. Then, launch the Asset Editor (under Assets, dropdown on the top left within the Creative Tools). Once you're in there, in the top left, click on the three dots `...` to the right of `Hytale:Hytale (Read Only)`, then on `Add Pack`.

Fill up the fields with something easy to remember and confirm. You will have created a valid `manifest.json` and basic structure in this folder here on your machine: `\AppData\Roaming\Hytale\UserData\Saves\[SaveFileName]\mods\[GroupName].[PackName]`

### 2. Adding a new instance
Locate this zip file: `AppData\Roaming\Hytale\install\release\package\game\latest\Assets.zip`. You need to look inside `\Server\Instances`. Pick a folder (e.g. `Zone1_Plains1`) and duplicate that folder's contents, together with its parent folder structure, into your `[GroupName].[PackName]` folder, renaming the very last folder.

You'll have something like this: `\Server\Instances\Testing_Biome1_Instance`. Inside this newly renamed folder, open `instance.bson` in a text editor and change the referenced WorldStructures file to `Testing_Biome1_WorldStructure`.

### 3. Adding the WorldStructure
Go back to the vanilla assets and find `\Server\HytaleGenerator\WorldStructures`. Duplicate an existing file (like `Zone1_Plains1.json`) into your pack, mirroring the folder structure once again and renaming the json file, so that you now have this within your asset pack: `\Server\HytaleGenerator\WorldStructures\Testing_Biome1_WorldStructure.json`.

Open your newly renamed `Testing_Biome1_WorldStructure.json` in a text editor. You need to remove all references to multiple biomes. Go through and ensure that for all the noise ranges, the biome is set to `Testing_Biome1` and nothing else.

In other words, the `"Biomes"` array needs to look like this:

```json
"Biomes": [{
      "Biome" : "Testing_Biome1",
      "Min" : -1,
      "Max" : 2
    }
  ],
```

### 4. Adding the Biome file
Now we need to make sure that biome actually exists. In your pack, create the folder path `\Server\HytaleGenerator\Biomes\Testing`.

Copy the `Plains1_River.json` file found in the vanilla `\Server\HytaleGenerator\Biomes\Plains1` folder into your new `Testing` folder, and rename it to `Testing_Biome1.json`.

### 5. Verifying the Instance
You should now have a new working instance available. In-game, use Creative Tools > World > Instance to warp to `Testing_Biome1_Instance`. Once there, double check that the instance is generating what seems to be an endless river-adjacent type of terrain.

### 6. Live Editing with /viewport
Position yourself in an area you'd like to edit and run the `/viewport --radius 3` command. This will make it so the area in a 3-chunk radius will update upon editing the biome file.

Open the node editor (Creative Tools > Assets > Assets Node Editor) and load the biome file `Testing_Biome1.json` located in `Server\HytaleGenerator\Biomes\Testing`. You can also open this file in a text editor if you so choose.

In order to check if things work, I suggest locating a block type, such as `Water_Source` or `Soil_Grass`, and replacing it with something else, such as `Lava_Source` or `Soil_Pathway`. This will make the change obvious and immediate.
