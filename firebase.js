// Firebase configuration
// Replace these values with your Firebase project config
const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "your-app-id"
};

// Initialize Firebase
import { initializeApp } from 'firebase/app';

// Initialize Firebase app
const app = initializeApp(firebaseConfig);

export default app;

// Export Firebase services for use in components
export { app };
