
import React from 'react';
import { EstimationResult } from '../types';

interface ResultDisplayProps {
  result: EstimationResult;
  onReset: () => void;
}

const ResultDisplay: React.FC<ResultDisplayProps> = ({ result, onReset }) => {
  return (
    <div className="bg-blue-50 border-l-4 border-[#0B3D91] p-6 rounded-lg space-y-4 animate-fade-in">
      <h2 className="text-2xl font-bold text-[#0B3D91]">Estimation Complete!</h2>
      
      <div className="grid grid-cols-2 gap-4 text-lg">
        <div className="font-semibold text-gray-700">Material:</div>
        <div className="text-right font-bold text-[#0B3D91]">{result.material}</div>
        
        <div className="font-semibold text-gray-700">Weight:</div>
        <div className="text-right">{result.weight.toLocaleString()} lbs</div>
        
        <div className="font-semibold text-gray-700">Price / lb:</div>
        <div className="text-right">${result.pricePerLb.toFixed(2)}</div>
      </div>
      
      <div className="border-t border-gray-300 my-4"></div>
      
      <div className="text-center">
        <p className="text-gray-600">Estimated Total Value</p>
        <p className="text-4xl font-extrabold text-green-600 tracking-tight">
          ${result.totalValue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
        </p>
      </div>
      
      <button
        onClick={onReset}
        className="w-full flex justify-center py-3 px-4 mt-4 border border-transparent rounded-lg shadow-sm text-base font-medium text-white bg-[#0B3D91] hover:bg-blue-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
      >
        Start New Estimate
      </button>
    </div>
  );
};

export default ResultDisplay;
