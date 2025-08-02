# Maestro Tests for Plant Doctor

This directory contains UI automation tests for the Plant Doctor app using [Maestro](https://maestro.mobile.dev/).

## Prerequisites

1. Install Maestro CLI:
   ```bash
   curl -Ls "https://get.maestro.mobile.dev" | bash
   ```

2. Ensure you have either:
   - A physical device connected via USB (with USB debugging enabled)
   - An Android emulator running
   - An iOS simulator running

## Preparing Test Assets

For the happy path diagnosis test (`04_happy_path_diagnosis.yaml`), you need to:
1. Add a maize plant image with early blight disease to `maestro/assets/maize_early_blight.jpg`
2. Ensure the image clearly shows brown leaves with holes for accurate AI detection

## Running Tests

### Run all tests:
```bash
maestro test maestro/
```

### Run a specific test:
```bash
maestro test maestro/flows/01_app_launch.yaml
```

### Run tests with cloud recording:
```bash
maestro cloud maestro/
```

## Test Structure

- `config.yaml` - Main Maestro configuration
- `flows/` - Directory containing all test flows
  - `01_app_launch.yaml` - Basic app launch test
  - `02_chat_interaction.yaml` - Chat interface and message input test
  - `03_settings_menu.yaml` - Menu and settings navigation test
  - `04_happy_path_diagnosis.yaml` - Complete disease diagnosis flow with AI model
- `assets/` - Directory for test images
  - Place `maize_early_blight.jpg` here for the diagnosis test

## Writing New Tests

1. Create a new YAML file in the `flows/` directory
2. Start with the app ID: `appId: dev.przbadu.plantdoctor`
3. Add test steps using Maestro commands

Example test structure:
```yaml
appId: dev.przbadu.plantdoctor
---
- launchApp
- assertVisible: "Expected Text"
- tapOn: "Button Text"
- takeScreenshot: screenshot_name
```

## Common Maestro Commands

- `launchApp` - Launch the application
- `tapOn` - Tap on an element by text
- `assertVisible` - Assert that text is visible
- `scrollUntilVisible` - Scroll until text is visible
- `pressKey` - Press device keys (back, home, etc.)
- `takeScreenshot` - Capture a screenshot
- `waitForAnimationToEnd` - Wait for animations to complete

## Debugging

Run tests in debug mode:
```bash
maestro test --debug maestro/flows/01_app_launch.yaml
```

View device hierarchy:
```bash
maestro studio
```

## CI/CD Integration

Add to your CI/CD pipeline:
```bash
# Install Maestro
curl -Ls "https://get.maestro.mobile.dev" | bash

# Run tests
maestro test maestro/
```

For more information, visit the [Maestro documentation](https://maestro.mobile.dev/docs).