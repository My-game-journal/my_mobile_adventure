# Input Mapping Summary

## Current Input Actions from project.godot:

| Action Name | Keyboard Key | Physical Keycode | Description |
|-------------|--------------|------------------|-------------|
| `move_left_button` | Left Arrow | 4194319 | Move character left |
| `move_right_button` | Right Arrow | 4194321 | Move character right |
| `jump_button` | A | 65 | Jump action |
| `attack_button` | W | 87 | Attack (combo system) |
| `roll_button` | S | 83 | Roll/dodge |
| `shield_button` | D | 68 | Shield (hold to block) |
| `pause_menu_button` | Escape | 4194305 | Pause game |

## Implementation:

### Player Movement:
- **Keyboard**: `Input.get_axis("move_left_button", "move_right_button")`
- **Mobile**: Touch buttons connected to mobile_direction variable

### Player Actions:
- **Jump**: `Input.is_action_just_pressed("jump_button")` + mobile_jump_pressed
- **Roll**: `Input.is_action_just_pressed("roll_button")` + mobile_roll_pressed  
- **Attack**: `Input.is_action_just_pressed("attack_button")` + mobile_attack_pressed
- **Shield**: `Input.is_action_pressed("shield_button")` + mobile_shield_active

### World/UI:
- **Pause**: `Input.is_action_pressed("pause_menu_button")` in world.gd

## Key Layout (WASD + Arrows):
```
     W (Attack)
A ← → D (Shield)
     S (Roll)

Arrow Keys: Movement
Escape: Pause
```

This provides intuitive controls for testing while maintaining mobile touch compatibility.
