# WebRTC Custom Build Demo

This repository contains:

- ✅ Custom build of WebRTC M110 (commit `218b56e`)
- 🛠️ Patch that adds random audio noise in `AudioProcessingImpl`
- 📦 Final `WebRTC.xcframework` (device + simulator)
- 📂 Folder structure prepared for demo iOS app integration

## Patches

All code modifications live in:
- `patches/add_noise.patch`

## Building Notes

Framework was built for:
- `ios_arm64`
- `ios_sim_arm64_x86_64`

Then combined via:

```bash
xcodebuild -create-xcframework \
  -framework out/ios_arm64/WebRTC.framework \
  -framework out/ios_sim_arm64_x86_64/WebRTC.framework \
  -output WebRTC.xcframework

