# Plant Doctor - Emulator Limitations

## x86_64 Emulator Compatibility Issue

The Plant Doctor app uses Google's Gemma models through the `flutter_gemma` package, which has specific hardware requirements. Unfortunately, **x86_64 Android emulators are not supported** due to missing OpenCL libraries and hardware acceleration requirements.

### Error You May See
```
Failed to open OpenCL library: UNKNOWN: Can not open OpenCL library on this device - dlopen failed: library "libvndksupport.so" not found
Fatal signal 11 (SIGSEGV), code 1 (SEGV_MAPERR)
```

### Solutions

1. **Use ARM64 Emulator** (Recommended for testing)
   - Create a new AVD with ARM64 architecture
   - Note: ARM64 emulators are slower on x86_64 host machines

2. **Use Physical Android Device** (Best performance)
   - Connect a real Android device via USB
   - Enable Developer Mode and USB Debugging
   - Run `flutter run` with device connected

3. **Test with Smaller Models**
   - Try the "Test Download" model first
   - This helps verify download functionality without AI initialization

### Creating ARM64 Emulator

1. Open Android Studio AVD Manager
2. Create New Virtual Device
3. Select a device definition
4. Choose system image with **arm64-v8a** ABI
5. Download if necessary (will be slower than x86_64)
6. Complete AVD creation

### Running on Physical Device

```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

### Known Working Configurations

- Physical Android devices (ARM processors)
- ARM64 Android emulators (slower but functional)
- Android API 24+ (Android 7.0+)

### Not Supported

- x86 Android emulators
- x86_64 Android emulators
- Android API < 24