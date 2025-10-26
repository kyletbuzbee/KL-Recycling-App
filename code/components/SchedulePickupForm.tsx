
import React, { useState } from 'react';
import { PickupFormData } from '../types';

interface SchedulePickupFormProps {
  onFormSubmit: (formData: PickupFormData) => void;
  isLoading: boolean;
}

const SchedulePickupForm: React.FC<SchedulePickupFormProps> = ({ onFormSubmit, isLoading }) => {
  const [formData, setFormData] = useState<PickupFormData>({ name: '', phone: '', notes: '' });
  const [errors, setErrors] = useState<{ name?: string; phone?: string; notes?: string }>({});

  const validate = (): boolean => {
    const newErrors: { name?: string; phone?: string; notes?: string } = {};
    if (!formData.name.trim()) newErrors.name = 'Name is required.';
    if (!formData.phone.trim()) newErrors.phone = 'Phone number is required.';
    if (!formData.notes.trim()) newErrors.notes = 'Please provide some details for your pickup.';
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (validate()) {
      onFormSubmit(formData);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <h2 className="text-xl font-bold text-center text-[#4A4A4A]">Schedule a Pickup</h2>
      <div>
        <label htmlFor="name" className="block text-sm font-medium text-gray-700">Full Name</label>
        <input type="text" name="name" id="name" value={formData.name} onChange={handleChange} className={`mt-1 block w-full px-3 py-2 border ${errors.name ? 'border-red-500' : 'border-gray-300'} rounded-md shadow-sm focus:outline-none focus:ring-[#3B82F6] focus:border-[#3B82F6]`} />
        {errors.name && <p className="mt-1 text-sm text-red-600">{errors.name}</p>}
      </div>
      <div>
        <label htmlFor="phone" className="block text-sm font-medium text-gray-700">Phone Number</label>
        <input type="tel" name="phone" id="phone" value={formData.phone} onChange={handleChange} className={`mt-1 block w-full px-3 py-2 border ${errors.phone ? 'border-red-500' : 'border-gray-300'} rounded-md shadow-sm focus:outline-none focus:ring-[#3B82F6] focus:border-[#3B82F6]`} />
        {errors.phone && <p className="mt-1 text-sm text-red-600">{errors.phone}</p>}
      </div>
      <div>
        <label htmlFor="notes" className="block text-sm font-medium text-gray-700">Pickup Details & Notes</label>
        <textarea name="notes" id="notes" rows={6} value={formData.notes} onChange={handleChange} placeholder="Please provide the pickup address, type of material, estimated amount, and any special instructions (e.g., 'Need a 30-yard roll-off at 123 Main St for mixed steel. Gate code is #4567.')" className={`mt-1 block w-full px-3 py-2 border ${errors.notes ? 'border-red-500' : 'border-gray-300'} rounded-md shadow-sm focus:outline-none focus:ring-[#3B82F6] focus:border-[#3B82F6]`}></textarea>
        {errors.notes && <p className="mt-1 text-sm text-red-600">{errors.notes}</p>}
      </div>
      <button type="submit" disabled={isLoading} className="w-full flex justify-center py-3 px-4 border border-transparent rounded-lg shadow-sm text-base font-medium text-white bg-[#3B82F6] hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors">
        {isLoading ? 'Processing...' : 'Submit Request'}
      </button>
    </form>
  );
};

export default SchedulePickupForm;
