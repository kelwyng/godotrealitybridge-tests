# GodotRealityBridge Tests

Standalone Godot project for manually exercising GodotRealityKit behavior on
macOS, the visionOS Simulator, and Apple Vision Pro.

The scene includes portal crossing, interaction and physics objects, dynamic
[MultiMesh](https://docs.godotengine.org/en/stable/classes/class_multimesh.html)
coin counts, and targeted Label3D regression reproducers.

## GodotRealityKit dependency

The built plugin is intentionally not committed. Install a current build at:

```text
addons/GodotRealityKit/
```

The local working copy retains the plugin that was used while developing these
tests. For a fresh clone, build GodotRealityKit and copy its generated addon
directory into the path above.

## Running

Open `project.godot` with the custom Godot macOS editor.

Use Godot's `visionOS` export preset to generate an Xcode project, then select
the simulator or headset destination and build it in Xcode.

## Destructive regression tests

- The red button intentionally attempts to reproduce the Label3D surface-count
  crash on an unpatched bridge.
- The amber button attempts to reproduce the dynamic font-atlas deadlock. The
  cyan hand freezes when the SceneTree deadlocks.

## Font atlas modes

`font_atlas_modes.tscn` is the focused simulator rendering test. The orange
labels use a default non-MSDF LA8 atlas and must receive the simulator swizzle.
The blue labels use an MSDF system font and must remain on the existing MSDF
path. The rainbow uses the bundled Noto Color Emoji font and must remain RGBA.
Run this scene directly when validating Label3D atlas changes. The font is from
Google's Noto Emoji project and its OFL 1.1 license is stored beside it.

The main scene does not load Noto Color Emoji at startup. Use its red
`ADD NOTO EMOJI` button to load and add the rainbow label on demand.
