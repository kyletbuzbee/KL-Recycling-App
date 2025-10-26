# KL Recycling Mobile App

A comprehensive Flutter mobile application for KL Recycling, providing a complete digital storefront with service scheduling, material education, and Texas compliance information.

## 🎯 Features Implemented

### **Core Digital Storefront**
- **🏠 Home Screen**: Professional service overview with Scrap Yard and Mobile Services options
- **🗺️ Service Area Map**: Interactive Google Maps showing 50-mile service radius from Tyler, TX
- **📞 Contact & Hours**: Click-to-call, email, and directions with complete business information

### **"Junk Shot" Service Scheduling**
- **💰 Quote System**: Multi-type quote requests with photo uploads
  - **Quote My Car**: Vehicle details, title verification, photo upload
  - **Quote My Scrap Pile**: Business/farm scrap collection requests
  - **Request a Bin**: Roll-off container rental with delivery scheduling

### **Customer Education & Compliance**
- **📚 Materials Guide**: Visual guide showing what they buy vs. don't buy
- **⚖️ Texas Compliance**: Complete legal guide for scrap metal transactions
- **❓ FAQ Section**: 10 comprehensive Q&As about recycling services
- **📋 Lead Capture Forms**: Professional quote forms with validation

## 🛠️ Technology Stack

- **Framework**: Flutter 3.0+ with Dart
- **State Management**: Provider pattern
- **UI**: Material Design 3
- **Maps**: Google Maps Flutter
- **Location**: Geolocator and Geocoding
- **Networking**: HTTP package
- **Storage**: Shared Preferences
- **Media**: Image Picker and Cached Network Image
- **Backend Integration**: RESTful API integration

## 🚀 Launch Instructions

### **Backend Setup (Required)**

#### **1. Install and Configure Cassandra Database**

**Prerequisites:**
- Java 8+ (required for Cassandra)
- Cassandra 3.x or 4.x

**Installation:**
```bash
# For macOS with Homebrew
brew install cassandra

# For Ubuntu/Debian
sudo apt-get install cassandra

# For Windows, download from Apache Cassandra website
# Extract to C:\Program Files\apache-cassandra\
```

**🔑 Enable Authentication (CRITICAL):**
For client drivers to successfully authenticate with username/password, authentication must be enabled on Cassandra cluster nodes:

1. **Edit cassandra.yaml configuration:**
   ```bash
   # macOS/Linux: /opt/homebrew/etc/cassandra/cassandra.yaml (Homebrew)
   # Ubuntu/Debian: /etc/cassandra/cassandra.yaml
   # Windows: C:\Program Files\apache-cassandra\conf\cassandra.yaml
   ```

2. **Set the authenticator property:**
   ```yaml
   authenticator: PasswordAuthenticator
   ```

3. **Restart Cassandra:**
   ```bash
   # macOS with Homebrew
   brew services restart cassandra

   # Linux systems
   sudo systemctl restart cassandra

   # Or manually
   cassandra -f
   ```

**⚠️ Default Credentials:** The default superuser credentials are `cassandra` / `cassandra` - **change these immediately for security!**

#### **2. Set Up Backend Environment**

```bash
cd backend
npm install
```

2. **Configure Environment Variables:**
   ```bash
   cp ../.env.example .env
   # Edit .env with your actual configuration
   ```

3. **Initialize Database:**
   ```bash
   # Start Cassandra if not running
   npm run setup-db  # Runs setup_cassandra.cql script
   ```

4. **Start Backend Server:**
   ```bash
   npm start  # Runs on localhost:3000
   ```

### **Frontend Setup**

#### **Prerequisites You Need To Install:**

1. **Flutter SDK** (https://flutter.dev/docs/get-started/install)
2. **Android Studio** (for Android development)
3. **Xcode** (for iOS development on macOS)
4. **VS Code** with Flutter/Dart extensions

### **Step-by-Step Setup:**

#### **1. Install Flutter**
```bash
# Download and install Flutter SDK from flutter.dev
# Add Flutter to your PATH
flutter doctor  # Verify installation
```

#### **2. Set Up Your Development Environment**

**For Android:**
- Install Android Studio
- Create an Android Virtual Device (AVD)
- Accept Android licenses: `flutter doctor --android-licenses`

**For iOS (macOS only):**
- Install Xcode from App Store
- Accept Xcode license: `sudo xcodebuild -license accept`

#### **3. Configure Firebase (Required)**

**Add Real Firebase Values:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create/select your project
3. In `android/app/google-services.json`:
   - Replace `REPLACE_WITH_YOUR_PROJECT_NUMBER` with your project number
   - Replace `REPLACE_WITH_YOUR_API_KEY` with your API key
   - Replace `REPLACE_WITH_YOUR_APP_ID` with your app ID

4. In `lib/firebase_options.dart`:
   - Replace the placeholder values with your actual Firebase config

#### **4. Install Dependencies**
```bash
flutter pub get
```

#### **5. Launch the App**

**For Android:**
```bash
flutter run android
```

**For iOS:**
```bash
flutter run ios
```

**For Web (optional):**
```bash
flutter run web
```

**For VS Code Debugging:**
- Press F5 or use Run & Debug panel
- Select "kl_recycling_mobile" debug configuration

### **🔧 What You Need to Configure:**

#### **Firebase Setup (CRITICAL):**
1. **Create Firebase project** at console.firebase.google.com
2. **Add Android app** with package name `com.klrecycling.app`
3. **Add iOS app** (optional)
4. **Download google-services.json** and replace the placeholder
5. **Update firebase_options.dart** with real values

#### **API Configuration:**
- Update `lib/constants/app_constants.dart` ApiConstants.baseUrl with your backend URL
- Backend should handle these endpoints:
  - `POST /api/auth/login`
  - `POST /api/auth/register`
  - Quote submission endpoints (currently simulated)

#### **Optional Customizations:**
- **App Icon**: Replace `android/app/src/main/res/mipmap-*` folders
- **Font**: Add Inter font files to `assets/fonts/` if desired
- **Colors**: Modify `AppColors` in constants for branding
- **Contact Info**: Update phone/email/address in contact screen

### **📱 App Permissions Included:**

The app automatically requests these permissions:
- **Location**: For service area map and directions
- **Camera**: For photo uploads in quote forms
- **Storage**: For accessing gallery photos
- **Internet**: For API calls and maps

### **🧪 Testing Checklist:**

Before deploying, verify:
- ✅ Firebase connection works
- ✅ Maps load and show service area
- ✅ Contact buttons open phone/email/maps
- ✅ Quote forms submit successfully
- ✅ All screens navigate properly
- ✅ App builds without errors

### **📋 File Structure:**

```
kl_recycling_mobile/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── firebase_options.dart     # Firebase config
│   ├── constants/
│   │   └── app_constants.dart    # Colors, strings, API config
│   ├── providers/
│   │   └── auth_provider.dart    # Authentication state
│   └── screens/                  # All screen widgets
│       ├── home_screen.dart      # Main app home
│       ├── service_area_map_screen.dart
│       ├── contact_screen.dart
│       ├── quote_*.dart          # 4 quote-related screens
│       ├── materials_guide_screen.dart
│       ├── texas_compliance_screen.dart
│       ├── faq_screen.dart
│       ├── login_screen.dart
│       ├── services_screen.dart
│       └── profile_screen.dart
├── android/                      # Android configuration
├── ios/                         # iOS configuration
└── assets/                      # App assets (images, fonts)
```

### **🚨 Common Issues & Solutions:**

1. **"Flutter SDK not found"**: Add Flutter to your PATH
2. **Android license issues**: Run `flutter doctor --android-licenses`
3. **iOS build fails**: Run `flutter clean` then rebuild
4. **Maps don't load**: Check Google Maps API key in Android Manifest
5. **Firebase not working**: Verify google-services.json and firebase_options.dart

### **🎯 Production Deployment:**

**Android**: `flutter build apk --release`
**iOS**: `flutter build ios --release`

**App Store/Google Play Requirements:**
- Sign with proper certificates
- Update version numbers
- Configure app icons
- Set up push notifications (if needed)
- Test on physical devices

---

**🎉 Your KL Recycling app is now ready for development and testing! This comprehensive mobile experience will help drive customer engagement and streamline your lead generation process.**
