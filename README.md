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

### Build Info
- WebRTC Commit: `218b56e516386cd57c7513197528c3124bcd7ef3`
- SHA-256 (WebRTC.xcframework): `2598307f788ab668e0f42b2a1daef4306adbb9ec9c3959441064e8e84f7310ee`



Then combined via:

```bash
xcodebuild -create-xcframework \
  -framework out/ios_arm64/WebRTC.framework \
  -framework out/ios_sim_arm64_x86_64/WebRTC.framework \
  -output WebRTC.xcframework

