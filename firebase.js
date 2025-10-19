// Firebase configuration
// Replace these values with your Firebase project config
const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "kl-recycling-app-65775308.firebaseapp.com",
  projectId: "kl-recycling-app-65775308",
  storageBucket: "kl-recycling-app-65775308.appspot.com",
  messagingSenderId: "194953675577",
  appId: "your-app-id"
};

// Initialize Firebase
import { initializeApp } from 'firebase/app';

// Initialize Firebase app
const app = initializeApp(firebaseConfig);

export default app;

// Export Firebase services for use in components
export { app };
