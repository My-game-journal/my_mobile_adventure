# Attack Combo System - Troubleshooting Guide

## ✅ **Issues Fixed:**

1. **Logic Flow Problem**: The original combo logic had incorrect conditional flow
2. **State Checking**: Improved the attack input handling logic
3. **Combo Reset Timing**: Fixed when the combo index gets reset

## 🔧 **How the Combo System Now Works:**

### **Input Detection:**
```gdscript
if attack_input:
    if can_act:                    # Not attacking/rolling
        start_next_attack()        # Start new attack
    elif state == ATTACKING:       # Currently attacking
        queued_attack = true       # Queue next attack
```

### **Combo Sequence:**
1. **First Attack**: Press W (or click A1) → `attack_0` plays
2. **Second Attack**: Press W again during `attack_0` → queues `attack_1`
3. **Third Attack**: Press W again during `attack_1` → queues `attack_2`
4. **Reset**: After `attack_2` completes, combo resets to `attack_0`

### **Timing System:**
- **Combo Window**: 0.8 seconds (COMBO_TIMEOUT)
- **Auto Reset**: If no input within 0.8s, combo resets to first attack
- **Queue System**: Can queue one attack while current attack plays

## 🧪 **Testing the Combo:**

### **Method 1: Rapid Button Mashing**
1. Press W rapidly (3-4 times quickly)
2. Should see: attack_0 → attack_1 → attack_2 → attack_0...

### **Method 2: Timed Inputs**
1. Press W (attack_0 plays)
2. Wait for attack to almost finish
3. Press W again (should queue attack_1)
4. Repeat for attack_2

### **Method 3: UI Button Testing**
1. Click A1 button rapidly
2. Should work same as keyboard

## 🐛 **Debug Output Added:**

I've added debug prints to help you see what's happening:

```
Starting attack: attack_0 (index: 0)
Attack input detected - can_act: true, state: 0, queued_attack: false
Combo finish - queued_attack: true, combo_index: 1
Starting attack: attack_1 (index: 1)
...
```

## 📋 **Testing Checklist:**

- [ ] Single W press → attack_0 animation plays
- [ ] Rapid W presses → combo sequence plays
- [ ] Mobile A1 button → same behavior as keyboard
- [ ] Combo resets after 0.8s of no input
- [ ] Debug output shows correct sequence in console

## 🔄 **Common Issues & Solutions:**

**Problem**: Only first attack plays
- **Check**: Animation length vs. input timing
- **Solution**: Try pressing attack button near end of animation

**Problem**: Combo doesn't chain
- **Check**: Debug output for queued_attack status
- **Solution**: Verify `handle_combo_finish()` is being called

**Problem**: Animation gets stuck
- **Check**: All attack animations have proper frame counts
- **Solution**: Verify `is_last_frame()` function works correctly

## 🎮 **Controls Summary:**

- **Keyboard**: W key for attack combo
- **Mobile UI**: A1 button for attack combo
- **Mouse**: Click A1 button for attack combo

The combo system should now work properly with all input methods!
