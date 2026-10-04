# Robot walking and ground footprints

The battle camera follows the squad, which kept the existing static robot artwork near the screen centre while the ground moved. Robots now bob, squash subtly and lean during actual ground displacement, then return to their resting pose when stopped. Dragging remains the movement control; no automatic wandering changes player control or combat balance.

Each robot leaves alternating left/right ground marks every 0.025 arena units. Marks stay in world coordinates, fade over three seconds of simulation time and use a fixed 96-node pool. Resize/rotation rescales their recorded arena coordinates. Golden trails colour the marks gold; no gameplay stats change. Reduce Motion suppresses bob/squash/lean while retaining the positional ground trail. Pause freezes simulation and trail ageing.

Two core regression cases check distance-based spacing across different frame sizes, alternating feet, stopping, and teleport reset. The new UI case drags the actual arena, verifies squad displacement and increased step count, then verifies both stop changing after release. Its diagnostics are exposed only with the existing UI-testing launch flag. iPhone/iPad XCTest captures and GitHub workflow results will be recorded below after validation.

Physical iPad feedback prompted this change; the revised build still needs a device check for the animation's feel.
