# Guardian-Paws Run Instructions

## If you see "Connection closed before full header" error

This often happens when the app crashes during startup (e.g. Firebase not configured) or due to debug connection issues. Try:

1. **Run in release mode** (avoids debug service protocol):
   ```
   flutter run --release
   ```

2. **Run in profile mode**:
   ```
   flutter run --profile
   ```

3. **Ensure Firebase is configured** (optional, for push notifications):
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`
   - Without these, the app will still run but push notifications won't work.

## Quick test of safety check

1. Register as **Girl**
2. Enable **Companion Mode** (switch ON)
3. Set interval to **10 minutes**
4. Tap **"Test now (10 sec)"** – the cat safety check will appear in 10 seconds
5. If you haven't set a tap pattern, tap **"I'm safe"** to confirm

## Cat image

The cat image is positioned on the **right side** of the screen (peeking from the right) on the home card, tap pattern screen, and safety check dialog.
