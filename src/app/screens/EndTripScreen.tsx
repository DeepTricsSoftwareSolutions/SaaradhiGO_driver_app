import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { CheckCircle, MapPin, Navigation, Clock, DollarSign } from "lucide-react";
import { DriverButton } from "../components/DriverButton";
import { GlassCard } from "../components/GlassCard";

export function EndTripScreen() {
  const navigate = useNavigate();

  const fareBreakdown = {
    baseFare: 50,
    distanceFare: 85,
    timeFare: 35,
    total: 185,
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] p-6">
      {/* Success Animation */}
      <motion.div
        initial={{ scale: 0, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ type: "spring", duration: 0.6 }}
        className="mt-16 mb-12 flex flex-col items-center"
      >
        <div className="w-32 h-32 bg-gradient-to-br from-[#22C55E] to-[#16A34A] rounded-full flex items-center justify-center shadow-2xl shadow-[#22C55E]/50 mb-6">
          <CheckCircle className="w-20 h-20 text-white" />
        </div>
        <h1 className="text-3xl font-bold text-white mb-2">Trip Completed!</h1>
        <p className="text-[#94A3B8] text-lg">Great job, driver!</p>
      </motion.div>

      {/* Trip Summary */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="mb-6"
      >
        <GlassCard>
          <h3 className="text-white text-xl font-bold mb-6">Trip Summary</h3>
          
          <div className="space-y-4">
            <div className="flex items-start gap-4">
              <div className="w-10 h-10 bg-[#22C55E] rounded-xl flex items-center justify-center flex-shrink-0">
                <MapPin className="w-5 h-5 text-white" />
              </div>
              <div className="flex-1">
                <p className="text-[#94A3B8] text-sm">Pickup</p>
                <p className="text-white font-semibold">MG Road, Brigade Road</p>
              </div>
            </div>

            <div className="ml-5 border-l-2 border-dashed border-[#94A3B8] h-6" />

            <div className="flex items-start gap-4">
              <div className="w-10 h-10 bg-[#D4AF37] rounded-xl flex items-center justify-center flex-shrink-0">
                <Navigation className="w-5 h-5 text-[#0F1C2E]" />
              </div>
              <div className="flex-1">
                <p className="text-[#94A3B8] text-sm">Drop</p>
                <p className="text-white font-semibold">Koramangala, 5th Block</p>
              </div>
            </div>

            <div className="h-px bg-white/10 my-4" />

            <div className="grid grid-cols-2 gap-4">
              <div className="bg-[#0F1C2E]/50 rounded-2xl p-4">
                <p className="text-[#94A3B8] text-sm mb-1">Distance</p>
                <p className="text-white text-xl font-bold">8.5 km</p>
              </div>
              <div className="bg-[#0F1C2E]/50 rounded-2xl p-4">
                <p className="text-[#94A3B8] text-sm mb-1">Duration</p>
                <p className="text-white text-xl font-bold">28 min</p>
              </div>
            </div>
          </div>
        </GlassCard>
      </motion.div>

      {/* Fare Breakdown */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.3 }}
        className="mb-6"
      >
        <GlassCard>
          <div className="flex items-center gap-3 mb-6">
            <DollarSign className="w-6 h-6 text-[#D4AF37]" />
            <h3 className="text-white text-xl font-bold">Fare Breakdown</h3>
          </div>
          
          <div className="space-y-3">
            <div className="flex justify-between text-base">
              <span className="text-[#94A3B8]">Base Fare</span>
              <span className="text-white">₹{fareBreakdown.baseFare}</span>
            </div>
            <div className="flex justify-between text-base">
              <span className="text-[#94A3B8]">Distance Fare (8.5 km)</span>
              <span className="text-white">₹{fareBreakdown.distanceFare}</span>
            </div>
            <div className="flex justify-between text-base">
              <span className="text-[#94A3B8]">Time Fare (28 min)</span>
              <span className="text-white">₹{fareBreakdown.timeFare}</span>
            </div>
            
            <div className="h-px bg-white/20 my-4" />
            
            <div className="bg-gradient-to-r from-[#D4AF37]/20 to-[#F4D03F]/20 border border-[#D4AF37]/30 rounded-2xl p-4">
              <div className="flex justify-between items-center">
                <span className="text-white text-lg font-semibold">Total Earnings</span>
                <span className="text-[#D4AF37] text-3xl font-bold">₹{fareBreakdown.total}</span>
              </div>
            </div>
          </div>
        </GlassCard>
      </motion.div>

      {/* Actions */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.4 }}
      >
        <DriverButton
          onClick={() => navigate("/home")}
          variant="success"
          className="w-full mb-4"
        >
          Complete Trip
        </DriverButton>
        
        <button
          onClick={() => navigate("/home")}
          className="w-full text-[#94A3B8] text-base font-semibold py-4"
        >
          Report an Issue
        </button>
      </motion.div>
    </div>
  );
}
