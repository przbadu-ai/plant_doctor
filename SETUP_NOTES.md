# Plant Doctor Setup Notes

## Fixes Applied

1. **Fixed flutter_gemma imports**:
   - Added proper imports for `InferenceModel`, `InferenceChat`, `ModelType`, and `PreferredBackend`
   - Imported from `flutter_gemma/core/` subdirectories

2. **Fixed deprecated APIs**:
   - Changed `surfaceVariant` to `surfaceContainerHighest` 
   - Changed `withOpacity()` to `withValues(alpha:)`

3. **Fixed code quality issues**:
   - Removed print statements
   - Added mounted checks before using BuildContext
   - Made private fields final where appropriate
   - Removed unused imports

4. **Added platform permissions**:
   - Android: Camera, Internet, External Storage permissions in AndroidManifest.xml
   - iOS: NSCameraUsageDescription and NSPhotoLibraryUsageDescription in Info.plist

## Running the App

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run on device/emulator:
   ```bash
   flutter run
   ```

3. To run on specific platform:
   ```bash
   flutter run -d android  # For Android
   flutter run -d ios      # For iOS
   ```

## Next Steps

1. Test the app on a real device
2. Download one of the Gemma 3n models (E2B or E4B)
3. Test plant disease detection with sample images
4. Customize the AI prompts for better agricultural context
5. Add more plant disease data and remedies

## Model URLs

The app is configured to download models from:
- Gemma 3n E2B: https://huggingface.co/google/gemma-3n-E2B-it-litert-preview
- Gemma 3n E4B: https://huggingface.co/google/gemma-3n-E4B-it-litert-preview

Make sure you have a stable internet connection for the initial model download (~1.5GB).