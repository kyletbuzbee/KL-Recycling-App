
import React, { useState } from 'react';

interface EstimationFormProps {
  onSubmit: (weight: number) => void;
}

const EstimationForm: React.FC<EstimationFormProps> = ({ onSubmit }) => {
  const [weight, setWeight] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const weightNum = parseFloat(weight);
    if (isNaN(weightNum) || weightNum <= 0) {
      setError('Please enter a valid weight greater than 0.');
      return;
    }
    setError('');
    onSubmit(weightNum);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label htmlFor="weight" className="block text-sm font-medium text-gray-700">
          Estimated Weight (lbs)
        </label>
        <div className="mt-1 relative rounded-md shadow-sm">
          <input
            type="number"
            name="weight"
            id="weight"
            className="focus:ring-[#3B82F6] focus:border-[#3B82F6] block w-full pl-4 pr-12 sm:text-sm border-gray-300 rounded-md py-3"
            placeholder="e.g., 50"
            value={weight}
            onChange={(e) => setWeight(e.target.value)}
            aria-describedby="weight-error"
            step="0.01"
          />
          <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
            <span className="text-gray-500 sm:text-sm" id="price-currency">
              lbs
            </span>
          </div>
        </div>
        {error && <p className="mt-2 text-sm text-red-600" id="weight-error">{error}</p>}
      </div>
      <button
        type="submit"
        className="w-full flex justify-center py-3 px-4 border border-transparent rounded-lg shadow-sm text-base font-medium text-white bg-[#3B82F6] hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
      >
        Get Price Estimate
      </button>
    </form>
  );
};

export default EstimationForm;
