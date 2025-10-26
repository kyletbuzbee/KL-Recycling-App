
import React, { useState, useCallback } from 'react';
import { EstimationResult, MaterialType, PickupDetails, PickupFormData, Service } from './types';
import { MATERIAL_PRICES } from './constants';
import { identifyMaterial, extractPickupDetails } from './services/geminiService';
import ImageUploader from './components/ImageUploader';
import EstimationForm from './components/EstimationForm';
import ResultDisplay from './components/ResultDisplay';
import LoadingSpinner from './components/LoadingSpinner';
import Chatbot from './components/Chatbot';
import SchedulePickupForm from './components/SchedulePickupForm';
import PickupConfirmation from './components/PickupConfirmation';
import CoreServices from './components/CoreServices';

// Fix: Moved getCoreServices from constants.ts to App.tsx to handle JSX syntax.
const getCoreServices = (onSelectEstimator: () => void, onSelectSchedule: () => void): Service[] => [
  {
    title: 'Get Photo Estimate',
    description: 'Upload a photo of your scrap for an AI-powered price estimate.',
    icon: <svg xmlns="http://www.w3.org/2000/svg" className="h-10 w-10 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" /></svg>,
    action: onSelectEstimator,
    isActionable: true,
  },
  {
    title: 'Schedule a Pickup',
    description: 'Arrange for a container or schedule a pickup for large quantities.',
    icon: <svg xmlns="http://www.w3.org/2000/svg" className="h-10 w-10 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path d="M9 17a2 2 0 11-4 0 2 2 0 014 0zM19 17a2 2 0 11-4 0 2 2 0 014 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 16V6a1 1 0 00-1-1H4a1 1 0 00-1 1v10l2 2h8a1 1 0 001-1zM3 11h10" /></svg>,
    action: onSelectSchedule,
    isActionable: true,
  },
  {
    title: 'Mobile Car Crushing',
    description: 'We provide on-site car crushing services with our state-of-the-art mobile equipment.',
    icon: <svg xmlns="http://www.w3.org/2000/svg" className="h-10 w-10 text-[#3B82F6]" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 20l-5.447-2.724A1 1 0 013 16.382V9.618a1 1 0 011.447-.894L9 11m0 9l6-3m-6 3V11m6 8l5.447-2.724A1 1 0 0021 16.382V9.618a1 1 0 00-.553-.894L15 7m-6 4l6-3m0 11V7" /></svg>,
    isActionable: false,
  },
  {
    title: 'Oil & Gas Demolition',
    description: 'Specialized in safe and efficient demolition and cleanup for the oil and gas industry.',
    icon: <svg xmlns="http://www.w3.org/2000/svg" className="h-10 w-10 text-[#3B82F6]" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10m0-2s2 2 3 3m3-5s-2 2-3 3m-3-3s-2-2-3-3m12 14l-4-4m0 0l-4-4m4 4l4 4m-4-4l-4 4" /></svg>,
    isActionable: false,
  },
  {
    title: 'Roll-Off Containers',
    description: 'Flexible container rental services with 20, 30, and 40-yard sizes for your project needs.',
    icon: <svg xmlns="http://www.w3.org/2000/svg" className="h-10 w-10 text-[#3B82F6]" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M20 12H4" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4v16" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M18 8l4 4-4 4" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 8l-4 4 4 4" /></svg>,
    isActionable: false,
  },
  {
    title: 'Public Drop-Off',
    description: 'Two convenient locations for public drop-off with friendly staff to assist you.',
    icon: <svg xmlns="http://www.w3.org/2000/svg" className="h-10 w-10 text-[#3B82F6]" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" /></svg>,
    isActionable: false,
  },
];

const Header: React.FC = () => (
  <header className="bg-white shadow-md">
    <div className="max-w-5xl mx-auto py-4 px-4 sm:px-6 lg:px-8 flex items-center space-x-4">
      <svg className="w-12 h-12 text-[#0B3D91]" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path></svg>
      <div>
        <h1 className="text-2xl font-bold text-[#0B3D91]">K&L Recycling</h1>
        <p className="text-sm text-gray-600">Customer Portal</p>
      </div>
    </div>
  </header>
);

const Home: React.FC<{ services: Service[] }> = ({ services }) => (
    <div className="text-center">
        <h2 className="text-2xl font-bold text-[#4A4A4A]">Welcome to K&L Recycling</h2>
        <p className="text-gray-600 mt-2 mb-8">Your one-stop portal for scrap metal recycling services.</p>
        <CoreServices services={services} />
    </div>
);

const App: React.FC = () => {
  const [activeScreen, setActiveScreen] = useState<'home' | 'estimator' | 'schedule' | 'confirmation'>('home');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const [imageFile, setImageFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [estimationResult, setEstimationResult] = useState<EstimationResult | null>(null);

  const [pickupFormData, setPickupFormData] = useState<PickupFormData | null>(null);
  const [parsedPickupDetails, setParsedPickupDetails] = useState<PickupDetails | null>(null);

  const resetToHome = () => {
    setActiveScreen('home');
    setIsLoading(false);
    setError(null);
    setImageFile(null);
    setPreviewUrl(null);
    setEstimationResult(null);
    setPickupFormData(null);
    setParsedPickupDetails(null);
  };

  const handleImageSelect = useCallback((file: File) => {
    setImageFile(file);
    setPreviewUrl(URL.createObjectURL(file));
    setEstimationResult(null);
    setError(null);
  }, []);

  const handleGetEstimate = async (weight: number) => {
    if (!imageFile) return;
    setIsLoading(true);
    setError(null);
    try {
      const material = await identifyMaterial(imageFile);
      if (material === MaterialType.UNKNOWN) {
        setError("Could not identify the material. Please try a clearer photo.");
      } else {
        const pricePerLb = MATERIAL_PRICES[material];
        setEstimationResult({ material, weight, pricePerLb, totalValue: pricePerLb * weight });
      }
    } catch (err) {
      setError("An unexpected error occurred during estimation.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleScheduleSubmit = async (formData: PickupFormData) => {
    setIsLoading(true);
    setError(null);
    setPickupFormData(formData);
    try {
      const details = await extractPickupDetails(formData.notes);
      setParsedPickupDetails(details);
      setActiveScreen('confirmation');
    } catch (err) {
      setError("Failed to process pickup details. Please try again.");
    } finally {
      setIsLoading(false);
    }
  };

  const handlePickupConfirm = () => {
    alert("Pickup request sent successfully! We will contact you shortly to confirm. (This is a demo)");
    resetToHome();
  };

  const services = getCoreServices(
    () => setActiveScreen('estimator'),
    () => setActiveScreen('schedule')
  );

  const renderContent = () => {
    switch (activeScreen) {
      case 'estimator':
        return (
          <>
            <h2 className="text-xl font-bold text-center text-[#4A4A4A] mb-6">AI Photo Estimator</h2>
            {!previewUrl ? (
              <ImageUploader onImageSelect={handleImageSelect} />
            ) : !estimationResult ? (
              <EstimationForm onSubmit={handleGetEstimate} />
            ) : (
              <ResultDisplay result={estimationResult} onReset={() => { setPreviewUrl(null); setEstimationResult(null); }} />
            )}
          </>
        );
      case 'schedule':
        return <SchedulePickupForm onFormSubmit={handleScheduleSubmit} isLoading={isLoading} />;
      case 'confirmation':
        if (!pickupFormData || !parsedPickupDetails) return null;
        return <PickupConfirmation originalData={pickupFormData} parsedDetails={parsedPickupDetails} onConfirm={handlePickupConfirm} onGoBack={() => setActiveScreen('schedule')} />;
      case 'home':
      default:
        return <Home services={services} />;
    }
  };

  return (
    <div className="min-h-screen bg-[#F8F9FA]">
      <Header />
      <main className="max-w-4xl mx-auto p-4 sm:p-6 lg:p-8">
        <div className="bg-white p-6 sm:p-8 rounded-xl shadow-lg space-y-6">
          {activeScreen !== 'home' && (
            <button onClick={resetToHome} className="text-sm text-[#3B82F6] hover:underline flex items-center gap-1 mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 19l-7-7 7-7" /></svg>
              Back to Home
            </button>
          )}
          {isLoading ? <LoadingSpinner /> : error ? (
            <div className="bg-red-100 border-l-4 border-red-500 text-red-700 p-4 rounded-md" role="alert">
              <p className="font-bold">Error</p>
              <p>{error}</p>
            </div>
          ) : renderContent()}
        </div>
        <footer className="text-center text-gray-500 text-xs mt-8">
          <p>&copy; {new Date().getFullYear()} K&L Recycling. All rights reserved.</p>
          <p>Estimates are for informational purposes only and are not guaranteed.</p>
        </footer>
      </main>
      <Chatbot />
    </div>
  );
};

export default App;
