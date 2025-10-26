
import React from 'react';
import { Service } from '../types';

interface CoreServicesProps {
  services: Service[];
}

const ServiceCard: React.FC<{ service: Service }> = ({ service }) => {
  const baseClasses = "p-6 rounded-xl text-left space-y-2 transition-all duration-300 w-full h-full flex flex-col";

  if (service.isActionable) {
    return (
      <button
        onClick={service.action}
        className={`${baseClasses} bg-[#0B3D91] text-white shadow-lg hover:shadow-xl hover:-translate-y-1`}
      >
        <div className="bg-white/20 rounded-full p-2 w-max">{service.icon}</div>
        <div className="flex-grow">
          <h3 className="text-lg font-bold">{service.title}</h3>
          <p className="text-sm text-blue-100">{service.description}</p>
        </div>
        <div className="text-right font-bold text-sm pt-2">Get Started &rarr;</div>
      </button>
    );
  }

  return (
    <div className={`${baseClasses} bg-gray-100 border border-gray-200`}>
      <div className="bg-white rounded-full p-2 w-max shadow-sm">{service.icon}</div>
      <h3 className="text-lg font-bold text-[#0B3D91]">{service.title}</h3>
      <p className="text-sm text-gray-600">{service.description}</p>
    </div>
  );
};

const CoreServices: React.FC<CoreServicesProps> = ({ services }) => {
  return (
    <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
      {services.map((service, index) => (
        <ServiceCard key={index} service={service} />
      ))}
    </div>
  );
};

export default CoreServices;
