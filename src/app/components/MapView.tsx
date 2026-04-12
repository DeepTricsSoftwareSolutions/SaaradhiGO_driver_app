import { motion } from "motion/react";

interface MapViewProps {
  className?: string;
  showRoute?: boolean;
  pickupLocation?: { lat: number; lng: number };
  dropLocation?: { lat: number; lng: number };
}

export function MapView({ className = "", showRoute = false }: MapViewProps) {
  return (
    <div className={`relative ${className}`}>
      {/* Map Placeholder - In real app, integrate Google Maps */}
      <div className="w-full h-full bg-gradient-to-br from-[#2A4A6F] to-[#1E3A5F] rounded-3xl overflow-hidden relative">
        {/* Grid pattern to simulate map */}
        <div className="absolute inset-0 opacity-20">
          <svg width="100%" height="100%">
            <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
              <path d="M 40 0 L 0 0 0 40" fill="none" stroke="white" strokeWidth="0.5" />
            </pattern>
            <rect width="100%" height="100%" fill="url(#grid)" />
          </svg>
        </div>
        
        {/* Roads simulation */}
        <svg className="absolute inset-0 w-full h-full">
          <line x1="0" y1="30%" x2="100%" y2="35%" stroke="#94A3B8" strokeWidth="3" opacity="0.4" />
          <line x1="40%" y1="0" x2="45%" y2="100%" stroke="#94A3B8" strokeWidth="3" opacity="0.4" />
          <line x1="0" y1="60%" x2="100%" y2="65%" stroke="#94A3B8" strokeWidth="2" opacity="0.3" />
        </svg>
        
        {/* Driver location marker */}
        <motion.div
          animate={{ scale: [1, 1.2, 1] }}
          transition={{ duration: 2, repeat: Infinity }}
          className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"
        >
          <div className="w-6 h-6 bg-[#D4AF37] rounded-full border-4 border-white shadow-lg" />
          <div className="absolute inset-0 bg-[#D4AF37] rounded-full animate-ping opacity-75" />
        </motion.div>
        
        {/* Route line if active */}
        {showRoute && (
          <>
            <svg className="absolute inset-0 w-full h-full">
              <motion.path
                initial={{ pathLength: 0 }}
                animate={{ pathLength: 1 }}
                transition={{ duration: 2 }}
                d="M 50% 50% Q 60% 30%, 80% 20%"
                stroke="#D4AF37"
                strokeWidth="4"
                fill="none"
                strokeDasharray="10,5"
              />
            </svg>
            
            {/* Pickup marker */}
            <div className="absolute top-[20%] right-[20%] w-8 h-8 bg-[#22C55E] rounded-full border-4 border-white shadow-lg flex items-center justify-center">
              <div className="w-3 h-3 bg-white rounded-full" />
            </div>
          </>
        )}
        
        {/* Map UI overlay text */}
        <div className="absolute bottom-4 left-4 text-white/60 text-xs">
          Google Maps Integration
        </div>
      </div>
    </div>
  );
}
