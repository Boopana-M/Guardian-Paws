# Guardian-Paws Setup Instructions

## Environment Configuration

### 1. Guardian Dashboard (React)
```bash
cd guardian_dashboard
cp .env.example .env
# Edit .env with your actual API keys
npm install
npm run dev
```

### 2. Flutter Mobile App
```bash
# For development with default values
flutter run

# For production with environment variables
flutter run --dart-define=PARSE_APP_ID=your_app_id \
  --dart-define=PARSE_CLIENT_KEY=your_client_key \
  --dart-define=PARSE_SERVER_URL=https://parseapi.back4app.com
```

### 3. Backend (Back4App Cloud Code)
1. Deploy `backend/parse_cloud/main.js` to Back4App
2. Set environment variables in Back4App dashboard:
   - `TWILIO_ACCOUNT_SID`
   - `TWILIO_AUTH_TOKEN`
   - `TWILIO_FROM_NUMBER`
   - `GUARDIAN_PAWS_PLAYSTORE_LINK`

### 4. Firebase (Optional - for push notifications)
- Add `google-services.json` to `android/app/`
- Add `GoogleService-Info.plist` to `ios/Runner/`

## Required API Keys
- Google Maps API Key (for dashboard)
- Back4App App ID, Client Key, Server URL
- Twilio credentials (for SMS alerts)
- Firebase configuration (for push notifications)

## Security Notes
- Never commit `.env` files or Firebase config files
- Use environment variables in production
- Keep API keys secure and rotate them regularly
