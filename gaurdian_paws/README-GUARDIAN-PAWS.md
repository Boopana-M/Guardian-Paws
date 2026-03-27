## Guardian-Paws Real-Time Safety System

This project contains:

- Flutter mobile app (`lib/`) for both girl and guardian roles
- Back4App Cloud Code (`backend/parse_cloud/main.js`) handling invites, alerts, and offline detection
- React + Vite guardian dashboard (`guardian_dashboard/`)

### Backend configuration

- Set Back4App app settings to use the provided APP_ID, CLIENT_KEY, and SERVER_URL.
- Deploy `backend/parse_cloud/main.js` as Cloud Code on Back4App.
- Configure environment variables on Back4App:
  - `TWILIO_ACCOUNT_SID`
  - `TWILIO_AUTH_TOKEN`
  - `TWILIO_FROM_NUMBER`
  - `GUARDIAN_PAWS_PLAYSTORE_LINK`

Cloud Jobs:

- Schedule the `monitorOfflineDevices` job to run every 5 minutes.

### Mobile Flutter app

- Add Firebase for push notifications (FCM) by including `google-services.json` / `GoogleService-Info.plist` and initializing Firebase.
- Configure location permissions in Android and iOS manifests.
- Build and run the Flutter app; girls can enable "Companion Mode" and set tap patterns, guardians get alerts.

### Guardian dashboard

- In `guardian_dashboard`, run `npm install` then `npm run dev`.
- Set `VITE_GOOGLE_MAPS_KEY` in an `.env` file for Google Maps.
- The dashboard polls Back4App every few seconds to show live user locations, trails, and status.

