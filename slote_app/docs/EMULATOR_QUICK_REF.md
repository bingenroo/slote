# Emulator Quick Reference

## Essential Commands

```bash
# List emulators
emu-list

# Launch emulator
emu <emulator_id>

# Check devices
flutter devices

# Run app
cd /Users/bingenro/Documents/Slote/slote_app
flutter pub get
flutter run
```

## One-Liner Workflow

```bash
emu-list && emu <emulator_id> && cd /Users/bingenro/Documents/Slote/slote_app && flutter pub get && flutter run
```

## Available Aliases

- `emu-list` - List all emulators
- `emu` - Launch emulator (shortest)
- `emu-launch` - Launch emulator (alternative)
- `launch-emu` - Run helper script

## Hot Reload Commands (While App Running)

- `r` - Hot reload
- `R` - Hot restart
- `d` - Open DevTools
- `q` - Quit

## Troubleshooting

```bash
# Clean and rebuild
cd /Users/bingenro/Documents/Slote/slote_app
flutter clean && flutter pub get && flutter run

# Check setup
flutter doctor -v
```
