
import React from 'react';
import { PickupDetails, PickupFormData } from '../types';

interface PickupConfirmationProps {
  originalData: PickupFormData;
  parsedDetails: PickupDetails;
  onConfirm: () => void;
  onGoBack: () => void;
}

const DetailRow: React.FC<{ label: string; value?: string }> = ({ label, value }) => {
  if (!value) return null;
  return (
    <div className="py-2 sm:grid sm:grid-cols-3 sm:gap-4">
      <dt className="text-sm font-medium text-gray-500">{label}</dt>
      <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">{value}</dd>
    </div>
  );
};

const PickupConfirmation: React.FC<PickupConfirmationProps> = ({ originalData, parsedDetails, onConfirm, onGoBack }) => {
  const hasParsedDetails = Object.values(parsedDetails).some(detail => detail);

  return (
    <div className="space-y-6">
      <h2 className="text-xl font-bold text-center text-[#4A4A4A]">Please Confirm Your Pickup Request</h2>
      
      <div className="bg-gray-50 p-4 rounded-lg border">
        <h3 className="font-semibold text-gray-800 mb-2">Your Request Summary:</h3>
        <p className="text-sm text-gray-600"><strong>Name:</strong> {originalData.name}</p>
        <p className="text-sm text-gray-600"><strong>Phone:</strong> {originalData.phone}</p>
      </div>

      {hasParsedDetails && (
        <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
          <h3 className="font-semibold text-[#0B3D91] mb-2">AI Processed Details:</h3>
          <p className="text-xs text-gray-500 mb-3">Our AI has structured the following details from your notes. Please review them for accuracy.</p>
          <dl className="divide-y divide-blue-200">
            <DetailRow label="Pickup Address" value={parsedDetails.address} />
            <DetailRow label="Container Size" value={parsedDetails.container_size} />
            <DetailRow label="Requested Date" value={parsedDetails.requested_date} />
            <DetailRow label="Special Instructions" value={parsedDetails.special_instructions} />
          </dl>
        </div>
      )}

      <div className="bg-gray-50 p-4 rounded-lg border">
        <h3 className="font-semibold text-gray-800 mb-2">Original Notes:</h3>
        <p className="text-sm text-gray-700 whitespace-pre-wrap italic">"{originalData.notes}"</p>
      </div>

      <div className="space-y-3 pt-4">
        <button onClick={onConfirm} className="w-full flex justify-center py-3 px-4 border border-transparent rounded-lg shadow-sm text-base font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-colors">
          Confirm & Schedule
        </button>
        <button onClick={onGoBack} className="w-full flex justify-center py-3 px-4 border border-gray-300 rounded-lg shadow-sm text-base font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors">
          Go Back & Edit
        </button>
      </div>
    </div>
  );
};

export default PickupConfirmation;
