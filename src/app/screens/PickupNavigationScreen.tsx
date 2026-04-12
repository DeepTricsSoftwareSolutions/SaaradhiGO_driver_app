import { useNavigate } from "react-router";
import { motion } from "motion/react";
import { ArrowLeft, Navigation, Phone, MessageCircle } from "lucide-react";
import { MapView } from "../components/MapView";
import { GlassCard } from "../components/GlassCard";
import { DriverButton } from "../components/DriverButton";

export function PickupNavigationScreen() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] relative">
      {/* Map Background */}
      <div className="absolute inset-0">
        <MapView className="w-full h-full" showRoute={true} />
      </div>

      {/* Top Bar */}
      <div className="relative z-10 p-6">
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="flex items-center gap-4"
        >
          <button
            onClick={() => navigate("/home")}
            className="w-12 h-12 bg-[#1E3A5F]/80 backdrop-blur-xl rounded-2xl flex items-center justify-center border border-white/10 shadow-xl"
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </button>
          <h2 className="text-xl font-semibold text-white">Navigate to Pickup</h2>
        </motion.div>

        {/* Navigation Info */}
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="mt-6"
        >
          <GlassCard className="backdrop-blur-2xl">
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 bg-[#22C55E] rounded-2xl flex items-center justify-center flex-shrink-0">
                <Navigation className="w-8 h-8 text-white" />
              </div>
              <div className="flex-1">
                <p className="text-[#94A3B8] text-sm mb-1">Distance</p>
                <h3 className="text-white text-2xl font-bold">2.3 km</h3>
              </div>
              <div className="flex-1 text-right">
                <p className="text-[#94A3B8] text-sm mb-1">ETA</p>
                <h3 className="text-[#D4AF37] text-2xl font-bold">8 min</h3>
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
          {/* Rider Info */}
          <div className="flex items-center gap-4 mb-6">
            <div className="w-16 h-16 bg-gradient-to-br from-[#D4AF37] to-[#F4D03F] rounded-2xl flex items-center justify-center text-2xl font-bold text-[#0F1C2E]">
              RK
            </div>
            <div className="flex-1">
              <h3 className="text-white text-lg font-bold">Rajesh Kumar</h3>
              <p className="text-[#94A3B8]">Economy • Cash Payment</p>
            </div>
            <div className="flex gap-2">
              <button className="w-12 h-12 bg-[#22C55E] rounded-2xl flex items-center justify-center">
                <Phone className="w-6 h-6 text-white" />
              </button>
              <button className="w-12 h-12 bg-[#D4AF37] rounded-2xl flex items-center justify-center">
                <MessageCircle className="w-6 h-6 text-[#0F1C2E]" />
              </button>
            </div>
          </div>

          {/* Pickup Location */}
          <div className="bg-[#0F1C2E]/50 rounded-2xl p-4 mb-6">
            <p className="text-[#94A3B8] text-sm mb-2">Pickup Location</p>
            <p className="text-white font-semibold">MG Road, Brigade Road Junction</p>
          </div>

          {/* Start Ride Button */}
          <DriverButton
            onClick={() => navigate("/start-ride")}
            variant="success"
            className="w-full"
          >
            Arrived at Pickup
          </DriverButton>
        </div>
      </motion.div>
    </div>
  );
}
