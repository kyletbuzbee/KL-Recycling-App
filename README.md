# KL-Recycling Mobile App

A React Native mobile application for K&L Recycling, providing a native mobile experience for their services, materials, quote requests, and location information.

## Features

- **Home**: Welcome screen with overview of services
- **Services**: Detailed view of recycling services (Roll-Off, Mobile Crushing, Demolition, Public Services)
- **Materials**: Browse and search accepted materials with categorizations
- **Quote**: Submit quote requests with form validation and offline storage
- **Schedule**: Dedicated screen for scheduling pickup requests with offline capability
- **Locations**: View all facility locations and contact information

## Technology Stack

- **Frontend**: React Native with Expo
- **Navigation**: React Navigation (Bottom Tabs)
- **API Calls**: Axios
- **Backend**: Node.js with Express (for form processing)

## Setup Instructions

### Prerequisites

- Node.js (v14 or later)
- npm or yarn
- For iOS: Xcode (macOS only)
- For Android: Android Studio

### Installation

1. Clone or download this project folder
2. Navigate to the project directory: `cd KL-Recycling Mobile App`
3. Install dependencies: `npm install`

### Backend Setup (Node.js API)

1. In a separate terminal, navigate to the project directory
2. Install backend dependencies:
   ```
   npm install express cors body-parser
   ```
3. Start the backend server:
   ```
   node server.js
   ```
   The API will run on http://localhost:3000

### Mobile App Setup

1. After installing dependencies, start the development server:
   ```
   npm start
   ```

2. This will open Expo DevTools in your browser

3. **For iOS Simulator (macOS only)**:
   ```
   npm run ios
   ```

4. **For Android Emulator**:
   ```
   npm run android
   ```

5. **For Physical Device**:
   - Install Expo Go app from App Store/Google Play
   - Scan QR code from Expo DevTools

### Important Note

Update the `API_BASE_URL` in `App.js` to use your computer's IP address when testing on a physical device:
- Replace `http://localhost:3000` with `http://YOUR_IP_ADDRESS:3000`
- Find your IP: Windows (`ipconfig`), macOS/Linux (`ifconfig` or `ip addr`)

## File Structure

```
KL-Recycling Mobile App/
├── App.js              # Main React Native app component
├── server.js           # Node.js API server
├── package.json        # Dependencies and scripts
└── README.md          # This file
```

## API Endpoints

- `POST /api/quote`: Submit quote request
- `POST /api/schedule`: Submit pickup scheduling request

## Supported Platforms

- iOS (iOS 11+)
- Android (API Level 21+)

## Future Enhancements

- Push notifications for quote responses
- Offline mode with local data
- GPS integration for location services
- Photo uploads for material identification
- Chat support integration
- Multi-language support
