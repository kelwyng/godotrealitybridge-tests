# GodotRealityBridge Tests

Standalone Godot project for manually exercising GodotRealityKit behavior on
macOS, the visionOS Simulator, and Apple Vision Pro.

The scene includes portal crossing, interaction and physics objects, dynamic
MultiMesh coin counts, and targeted Label3D regression reproducers.

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

To export, build, install, and launch:

```sh
./build-and-push.sh simulator
./build-and-push.sh headset
```

Set `GODOT_REALITYKIT_EDITOR` when the custom editor is not in the adjacent
`godotrealitybridge` workspace.

## Destructive regression tests

- The red button intentionally attempts to reproduce the Label3D surface-count
  crash on an unpatched bridge.
- The amber button attempts to reproduce the dynamic font-atlas deadlock. The
  cyan hand freezes when the SceneTree deadlocks.
