# GitHub Actions Setup for Android Release

## Prerequisites

You need to set up the following GitHub secrets for the build workflow:

1. **Generate a keystore** (if you don't have one):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Convert keystore to base64**:
   ```bash
   base64 -i upload-keystore.jks -o keystore_base64.txt
   # On macOS: base64 -i upload-keystore.jks > keystore_base64.txt
   # On Linux: base64 upload-keystore.jks > keystore_base64.txt
   ```

3. **Add secrets to GitHub**:
   - Go to Settings → Secrets and variables → Actions
   - Add the following secrets:
     - `KEYSTORE_BASE64`: Content of keystore_base64.txt
     - `KEYSTORE_PASSWORD`: Your keystore password
     - `KEY_PASSWORD`: Your key password
     - `KEY_ALIAS`: Your key alias (e.g., "upload")
     - `HUGGING_FACE_TOKEN`: Your Hugging Face API token (get from https://huggingface.co/settings/tokens)

## Triggering Releases

The workflow triggers automatically when you push a version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Or manually trigger from Actions tab → Build and Release Android APK → Run workflow

## Important Notes

- The keystore file should NEVER be committed to the repository
- Keep your keystore file and passwords secure
- Use the same keystore for all releases to maintain app continuity on Google Play