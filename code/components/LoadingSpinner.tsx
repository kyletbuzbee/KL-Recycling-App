
import React from 'react';

const LoadingSpinner: React.FC = () => {
  return (
    <div className="flex flex-col items-center justify-center space-y-4 p-8">
      <div className="w-12 h-12 border-4 border-t-transparent border-[#3B82F6] rounded-full animate-spin"></div>
      <p className="text-gray-600 font-medium">Analyzing your scrap metal...</p>
    </div>
  );
};

export default LoadingSpinner;
