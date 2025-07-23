# Input Controls for Testing on Laptop

This mobile game now supports multiple input methods for testing purposes on your laptop. You can use keyboard, mouse, and touch controls simultaneously.

## Keyboard Controls:

- **Movement**: Arrow Keys (Left/Right)
- **Jump**: A key
- **Roll**: S key
- **Attack**: W key - Single button combo system
- **Shield**: D key - Hold to shield
- **Pause**: Escape key

## Mouse Controls:

- **UI Interaction**: Click any mobile UI button with mouse
- **Visual Feedback**: Buttons highlight when hovered over
- **Movement**: Click and hold ◀ ▶ buttons
- **Actions**: Click JUMP, ROLL, A1 (attack), X (shield), PAUSE buttons

## Mobile Touch Controls:

- **Movement**: Touch buttons (◀ ▶)
- **Jump**: JUMP button
- **Roll**: ROLL button  
- **Attack**: A1 button (combo system)
- **Shield**: X button (hold to shield)
- **Pause**: PAUSE button

## Testing Features:

1. **Triple Input Support**: Keyboard + Mouse + Touch all work simultaneously
2. **Mouse Cursor**: Visible on laptop, hidden on mobile devices
3. **Button Hover Effects**: Visual feedback when hovering over UI buttons
4. **Click & Hold**: Mouse buttons work with press/release mechanics
5. **Combo System**: Single attack button/key cycles through attack_0 → attack_1 → attack_2

## Best for Testing:

- **Quick Testing**: Use keyboard (WASD + arrows)
- **UI Testing**: Use mouse to click mobile buttons
- **Mobile Simulation**: Use only mouse clicks on UI buttons
- **Full Testing**: Combine all input methods

## Development Notes:

- Mouse cursor automatically shows on desktop/laptop
- Mobile UI buttons are optimized for both touch and mouse
- All input methods trigger the same game logic
- Perfect for testing mobile UI without deploying to device
