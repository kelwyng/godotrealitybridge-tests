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
