# Getting Started with Scene 2 UWMF

## 1. Make sure that you have a compatible source port set up

In order to test your maps, you’ll need a source port that supports the
Universal Wolfenstein Map Format. These ports are known to support UWMF:

- [ECWolf]
- [LZWolf]\*

Make sure that you’re able to play at least one of the following games.

- Wolfenstein 3D, Shareware version\*
- Wolfenstein 3D, 6 episode registered version\*
- Spear of Destiny
- Spear of Destiny Demo\*
- Mission 2: Return to Danger\*
- Mission 3: Ultimate Challenge\*
- Super 3D Noah’s Ark\*

These games are the only ones that Scene 2 UWMF supports. [The ECWolf Wiki
provides more information about which game data files you’ll need from each
game.](https://maniacsvault.net/ecwolf/wiki/Game_data)

\* Not tested with Scene 2 UWMF yet, but probably works.

## 2. Make sure that you have a compatible version of [Godot]

Please use [Godot v3.4.4](https://downloads.tuxfamily.org/godotengine/3.4.4/).
I’ll start supporting the latest stable version of Godot once it’s in a stable
version of [nixpkgs](https://github.com/NixOS/nixpkgs).

## 3. Set up a Git repo for your maps

1. Make sure that you have [Git](https://git-scm.com/) installed.
2. Create a local copy of the Scene 2 UWMF repo:

		git clone <URL>

3. Change directory into your clone of the Scene 2 UWMF repo:

		cd scene-2-uwmf

4. Set up any submodules:

		git submodule update --init --recursive

5. _(Recommended)_ Use a separate branch for your changes:

	1. Create the branch:

			git branch <name>

	2. Switch to the branch:

			git checkout <name>

## 4. Import the project and extract base game graphics

1. Open Godot.
2. Use [Godot’s Project Manger] to import the Scene 2 UWMF project:

	1. Click “Import”.
	2. Click “Browse”.
	3. Navigate to the root of the Git repo that you created.
	4. Open the “project” directory.
	5. Choose “project.godot” (select it and then click “Open”).
	6. Click “Import & Edit”.

3. Extract the graphics from the game that you’re creating a level for:

	1. In [Godot’s playtest buttons][editor vocab], click on the triangular Play
	button. (Hint: if Godot’s test window freezes, then you may have
	forgotten to set up the Git submodule.)
	2. Specify the path to `ecwolf.pk3`. `ecwolf.pk3` comes with ECWolf. If
	you’re using LZWolf, then you can try using its `lzwolf.pk3` instead. If
	that doesn’t work, then download ECWolf and use its `ecwolf.pk3` (you’ll
	still be able to make maps for LZWolf).
	3. Specify the path to the game’s `VSWAP` file. The file’s extension is
	different for each game:

		- The shareware version of Wolfenstein 3D uses `VSWAP.WL1`
		- The 6 episode registered version of Wolfenstein 3D uses `VSWAP.WL6`
		- Spear of Destiny uses `VSWAP.SOD`
		- Spear of Destiny’s second mission uses `VSWAP.SD2`
		- Spear of Destiny’s third mission uses `VSWAP.SD3`
		- Super 3D Noah’s Ark uses `VSWAP.N3D`

	4. Click “Extract Graphics”.
	5. Once the process has finished, close out of the Graphics Extractor
	window.
	6. _(Optional)_ If you’re creating a level for Spear of Destiny’s
	Mission 2, then you can use the wall textures from both Mission 2 and
	from Spear of Destiny. Mission 3 works the same way. If you want to do
	so, then you’ll need to repeat steps 1–5 for `VSWAP.SOD`.
	7. If you want to create levels for an additional games, the repeat steps
	1–6 for each of those games.

## 5. Create a new level

1. Create a new scene that inherits from
`res://wolf_editing_tools/scenes_and_scripts/map/base_map.tscn`:

	1. In [Godot’s main menus][editor vocab], click on “Scene” then “New
	Scene”.
	2. In [Godot’s Scene dock][first look], click on the Instance Child
	Scene button. The Instance Child Scene button looks like a chain and is
	next to a button that’s shaped like a plus.
	3. In the “Open Base Scene” window, navigate to the
	`wolf_editing_tools/scenes_and_scripts/map` directory.
	4. Choose `base_map.tscn` (select it and then click “Open”).

2. _(Optional)_ Rename the scene’s root `Node`:

	1. In [Godot’s Scene dock][first look], find the `Node` named “BaseMap”.
	2. Right click on “BaseMap” and then click “Rename”.
	3. Type in a new name for the `Node`. [The Godot Docs recommend that you
	use PascalCase for the names of `Node`s.][style guide] This name won’t
	get used by the source port at all. It’s only used by Godot.

3. Save the scene:

	1. In [Godot’s main menus][editor vocab], click on “Scene” then “Save
	Scene”.
	2. Choose a directory to save the scene in. I recommend saving your maps
	in a new directory named “user_maps” inside `res://`. [The Godot Docs
	recommend that you use snake_case for directory names.][style guide]
	3. Choose name for your scene file. [The Godot Docs recommend that you
	use snake_case for filenames.][style guide] If you renamed your root
	`Node`, then I would recommend taking that name, converting it into
	snake_case and using it as the filename.

## 6. Create the bare minimum required for a level that doesn’t crash

1. Create a Tile:

	1. In [Godot’s Scene dock][first look], make sure that your scene’s root
	`Node` is selected. The scene’s root `Node` is the one at the top of the
	list.
	2. In [Godot’s Scene dock][first look], click on the Instance Child
	Scene button. The Instance Child Scene button looks like a chain and is
	next to a button that’s shaped like a plus.
	3. Choose `wolf_editing_tools/scenes_and_scripts/map/tile.tscn` (select
	it and then click “Open”).
	4. In [Godot’s Inspector][first look], find the “Texture East” property.
	At the moment, Texture East will be set to “[empty]”.
	5. To the right of Texture East’s value (“[empty]”), there should be a
	drop-down arrow. Click on that arrow.
	6. Click “New SingleColorTexture”.
	7. Repeat steps 4–6 for the Texture North, Texture South and Texture
	West properties.

2. Enable snapping. In [Godot’s toolbar][first look], click on the “Use Snap”
button. The “Use Snap” button looks like three dots with a magnet. This will
prevent you from moving Tiles into impossible positions (in UWMF, tiles must
have whole number coordinates).
3. Create 7 more Tiles:

	1. In [Godot’s Scene dock][first look], find the `Node` named “Tile”.
	2. Right click on it.
	3. Click “Duplicate”.
	4. Repeat steps 1–3 until there are 8 Tiles total.

4. Arrange the Tiles into an O shaped pattern. Make sure that you don’t
accidentally give one of the Tiles a negative coordinate or a Z coordinate
that isn’t 0. In other words, Tiles should be

	- east of the blue line,
	- south of the red line and
	- sitting on top of the square grid pattern.

	When you have a Tile selected, the red movement arrow will point east
	and the blue movement arrow will point south.

5. Create a player start:

	1. In [Godot’s Scene dock][first look], make sure that your scene’s root
	`Node` is selected.
	2. In [Godot’s Scene dock][first look], click on the Instance Child
	Scene button.
	3. Choose `wolf_editing_tools/scenes_and_scripts/map/thing.tscn`.
	4. Disable snapping. In [Godot’s toolbar][first look], click on the “Use
	Snap” button. The “Use Snap” button looks like three dots with a magnet.
	This will allow you to place the player start in the center of you map.
	5. Move the newly created Thing into the center of the O.

## 7. Test the level

1. In [Godot’s playtest buttons][editor vocab], click on the Play Scene button.
The Play Scene button looks like a clapperboard with a triangle on it.
2. A new window will appear. Once Scene 2 UWMF has finished generating a WAD
file for your map, that window will turn gray. Once the window is gray, close
out of it.
3. In [Godot’s main menus][editor vocab], click “Project” then “Open Project
Data Folder”.
4. In your file manager, you should see a file named “MAP01.WAD”. You can now
load that map in your source port and test it out. If you’re using ECWolf, then
you can

	- run

			ecwolf --file <path-to-MAP01.WAD>

	- or drag and drop MAP01.WAD onto ECWolf’s executable.

## 8. Next steps

Take a look at [Scene 2 UWMF’s reference document](Reference.md). It describes
everything that you can add to or customize about a map.

[ECWolf]: https://maniacsvault.net/ecwolf/
[editor vocab]: https://docs.godotengine.org/en/3.4/community/contributing/docs_writing_guidelines.html#common-vocabulary-to-use-in-godot-s-documentation
[first look]: https://docs.godotengine.org/en/3.4/getting_started/introduction/first_look_at_the_editor.html#id1
[Godot]: https://godotengine.org/
[LZWolf]: https://bitbucket.org/linuxwolf6/lzwolf/src/master/
[Godot’s Project Manger]: https://docs.godotengine.org/en/3.4/getting_started/introduction/first_look_at_the_editor.html#the-project-manager
[style guide]: https://docs.godotengine.org/en/3.4/tutorials/best_practices/project_organization.html?highlight=PascalCase#style-guide
