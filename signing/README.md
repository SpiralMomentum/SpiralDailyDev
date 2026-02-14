# Signing Configuration

This directory contains signing configurations for each app.

## Structure

```
signing/
├── {app_name}/
│   └── android/
│       ├── key.properties    # Keystore credentials (git-ignored)
│       └── release.keystore  # Keystore file (git-ignored)
```

## Local Development

Place your `key.properties` and `release.keystore` files in the appropriate
`signing/{app_name}/android/` directory. These files are git-ignored.

### key.properties format

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=<your-key-alias>
storeFile=release.keystore
```

## CI

In CI, these files are dynamically generated from GitHub Secrets:
- `ANDROID_KEYSTORE_{APP}_BASE64` - Base64-encoded keystore
- `ANDROID_STORE_PASSWORD_{APP}` - Keystore password
- `ANDROID_KEY_ALIAS_{APP}` - Key alias
- `ANDROID_KEY_PASSWORD_{APP}` - Key password
