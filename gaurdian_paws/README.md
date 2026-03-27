# 🐾 Guardian-Paws: Real-Time Safety Monitoring System

A comprehensive personal safety application designed to provide peace of mind for individuals and their loved ones through intelligent, real-time monitoring and emergency response capabilities.

## 🌟 Key Features

### 🛡️ **For Users (Girls/Women)**
- **Companion Mode**: Automated safety check-ins at customizable intervals
- **Tap Pattern Security**: Unique, discreet safety confirmation using personalized tap sequences
- **Real-Time Location Tracking**: Continuous location monitoring with trail history
- **Emergency Alerts**: Instant SOS notifications to designated guardians
- **Background Monitoring**: Works silently in the background without disrupting daily activities
- **Battery & Status Monitoring**: Guardian dashboard shows device status and battery levels

### 👥 **For Guardians**
- **Live Dashboard**: Real-time web interface monitoring multiple users simultaneously
- **Interactive Maps**: Google Maps integration showing current locations and movement trails
- **Instant Alerts**: Immediate notifications when safety checks are missed or emergencies triggered
- **Historical Data**: Complete timeline of check-ins, locations, and safety events
- **Multi-User Support**: Monitor multiple protected individuals from one dashboard

### 🚨 **Emergency Response**
- **SMS Alerts**: Automatic Twilio-powered SMS notifications to guardians
- **Push Notifications**: Firebase Cloud Messaging for instant mobile alerts
- **Escalation Protocols**: Configurable response procedures for different scenarios
- **Offline Detection**: Automated monitoring of device connectivity and offline status

## 🏗️ Architecture

### 📱 **Mobile App (Flutter)**
- Cross-platform support (iOS, Android, Web, Desktop)
- Material Design UI with smooth animations
- Background service integration for persistent monitoring
- Location services with geofencing capabilities
- Local notifications and alarm systems

### 🌐 **Guardian Dashboard (React + Vite)**
- Real-time data synchronization with Back4App
- Interactive Google Maps with live tracking
- Responsive design for desktop and mobile viewing
- WebSocket-like polling for instant updates
- Clean, intuitive interface for emergency management

### ⚙️ **Backend (Back4App Cloud Code)**
- Parse Server SDK for data management
- Cloud jobs for offline device monitoring
- Twilio integration for SMS alerts
- Secure user authentication and role management
- Scalable cloud infrastructure

## 🎯 Use Cases

- **Personal Safety**: Perfect for students, professionals, and individuals traveling alone
- **Family Protection**: Parents monitoring children's safety during daily activities
- **Elderly Care**: Family members keeping track of elderly relatives
- **Workplace Safety**: Organizations ensuring employee safety during field work
- **Travel Security**: Real-time monitoring during business trips or vacations

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (>= 3.11.1)
- Node.js (>= 16) for dashboard
- Back4App account for backend services
- Google Maps API key
- Twilio account (for SMS alerts)

### Installation
1. **Clone the repository**
   ```bash
   git clone https://github.com/Boopana-M/Guardian-Paws.git
   cd Guardian-Paws/gaurdian_paws
   ```

2. **Setup Dashboard**
   ```bash
   cd guardian_dashboard
   cp .env.example .env
   # Edit .env with your API keys
   npm install
   npm run dev
   ```

3. **Setup Mobile App**
   ```bash
   flutter pub get
   flutter run
   ```

4. **Configure Backend**
   - Deploy `backend/parse_cloud/main.js` to Back4App
   - Set environment variables in Back4App dashboard
   - Schedule cloud jobs for offline monitoring

For detailed setup instructions, see [SETUP.md](SETUP.md)

## 🔧 Configuration

The app uses environment variables for secure configuration:

- **Back4App**: App ID, Client Key, Server URL
- **Google Maps**: API key for dashboard mapping
- **Twilio**: Account SID, Auth Token, Phone number
- **Firebase**: Configuration for push notifications

See `.env.example` files for complete configuration templates.

## 🛡️ Security & Privacy

- **End-to-End Encryption**: All data transmission encrypted
- **Role-Based Access**: Clear separation between user and guardian roles
- **Privacy Controls**: Users control who can monitor their location
- **Data Minimization**: Only essential data collected and stored
- **Secure Authentication**: OAuth and token-based security

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on:

- Code of Conduct
- Development workflow
- Pull request process
- Issue reporting

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing cross-platform framework
- Back4App for providing the backend infrastructure
- Google Maps platform for location services
- Twilio for reliable SMS delivery
- Firebase for push notification services

## 📞 Support

For questions, support, or feature requests:
- Create an issue on GitHub
- Check our [FAQ](docs/FAQ.md)
- Review our [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

---

**Guardian-Paws**: Your silent companion in personal safety. 🐾✨
