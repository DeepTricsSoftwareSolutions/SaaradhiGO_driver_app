import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { Phone, MessageCircle, Navigation, AlertCircle } from "lucide-react";
import { MapView } from "../components/MapView";
import { GlassCard } from "../components/GlassCard";
import { DriverButton } from "../components/DriverButton";

export function LiveTripScreen() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] relative">
      {/* Map Background */}
      <div className="absolute inset-0">
        <MapView className="w-full h-full" showRoute={true} />
      </div>

      {/* Status Badge */}
      <motion.div
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="absolute top-8 left-1/2 -translate-x-1/2 z-20"
      >
        <div className="bg-[#D4AF37] text-[#0F1C2E] px-6 py-3 rounded-full font-bold text-base shadow-xl flex items-center gap-2">
          <div className="w-2 h-2 bg-[#0F1C2E] rounded-full animate-pulse" />
          Trip in Progress
        </div>
      </motion.div>

      {/* Top Info Card */}
      <div className="relative z-10 p-6 pt-24">
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.2 }}
        >
          <GlassCard className="backdrop-blur-2xl">
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 bg-[#D4AF37] rounded-2xl flex items-center justify-center flex-shrink-0">
                <Navigation className="w-8 h-8 text-[#0F1C2E]" />
              </div>
              <div className="flex-1">
                <p className="text-[#94A3B8] text-sm mb-1">Distance Remaining</p>
                <h3 className="text-white text-2xl font-bold">3.2 km</h3>
              </div>
              <div className="flex-1 text-right">
                <p className="text-[#94A3B8] text-sm mb-1">ETA</p>
                <h3 className="text-[#D4AF37] text-2xl font-bold">12 min</h3>
              </div>
            </div>
          </GlassCard>
        </motion.div>
      </div>

      {/* Bottom Action Bar */}
      <motion.div
        initial={{ y: 100, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.4 }}
        className="absolute bottom-0 left-0 right-0 p-6"
      >
        <div className="bg-[#1E3A5F]/90 backdrop-blur-2xl border border-white/10 rounded-3xl p-6 shadow-2xl">
          {/* Quick Actions */}
          <div className="flex gap-3 mb-6">
            <button className="flex-1 bg-[#22C55E] hover:bg-[#22C55E]/90 rounded-2xl p-4 flex items-center justify-center gap-2 transition-colors">
              <Phone className="w-5 h-5 text-white" />
              <span className="text-white font-semibold">Call</span>
            </button>
            <button className="flex-1 bg-[#D4AF37] hover:bg-[#D4AF37]/90 rounded-2xl p-4 flex items-center justify-center gap-2 transition-colors">
              <MessageCircle className="w-5 h-5 text-[#0F1C2E]" />
              <span className="text-[#0F1C2E] font-semibold">Chat</span>
            </button>
            <button 
              onClick={() => navigate("/safety")}
              className="flex-1 bg-[#EF4444] hover:bg-[#EF4444]/90 rounded-2xl p-4 flex items-center justify-center gap-2 transition-colors"
            >
              <AlertCircle className="w-5 h-5 text-white" />
              <span className="text-white font-semibold">SOS</span>
            </button>
          </div>

          {/* Rider Info */}
          <div className="bg-[#0F1C2E]/50 rounded-2xl p-4 mb-6">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-12 h-12 bg-gradient-to-br from-[#D4AF37] to-[#F4D03F] rounded-xl flex items-center justify-center text-lg font-bold text-[#0F1C2E]">
                RK
              </div>
              <div className="flex-1">
                <h3 className="text-white font-bold">Rajesh Kumar</h3>
                <p className="text-[#94A3B8] text-sm">4.8 ★ • 234 rides</p>
              </div>
            </div>
            <div className="h-px bg-white/10 my-3" />
            <div>
              <p className="text-[#94A3B8] text-sm mb-1">Destination</p>
              <p className="text-white font-semibold">Koramangala, 5th Block</p>
            </div>
          </div>

          {/* Fare Preview */}
          <div className="bg-gradient-to-r from-[#D4AF37]/20 to-[#F4D03F]/20 border border-[#D4AF37]/30 rounded-2xl p-4 mb-6">
            <div className="flex items-center justify-between">
              <span className="text-[#94A3B8]">Estimated Fare</span>
              <span className="text-[#D4AF37] text-xl font-bold">₹185</span>
            </div>
          </div>

          {/* End Trip Button */}
          <DriverButton
            onClick={() => navigate("/end-trip")}
            variant="success"
            className="w-full"
          >
            End Trip
          </DriverButton>
        </div>
      </motion.div>
    </div>
  );
}
