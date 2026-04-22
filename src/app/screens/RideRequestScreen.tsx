import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { MapPin, Navigation, DollarSign, Clock } from "lucide-react";
import { BottomSheet } from "../components/BottomSheet";
import { DriverButton } from "../components/DriverButton";
import { MapView } from "../components/MapView";

export function RideRequestScreen() {
  const navigate = useNavigate();
  const [showRequest, setShowRequest] = useState(true);
  const [timer, setTimer] = useState(15);

  useEffect(() => {
    if (timer > 0 && showRequest) {
      const interval = setInterval(() => {
        setTimer((prev) => prev - 1);
      }, 1000);
      return () => clearInterval(interval);
    } else if (timer === 0) {
      setShowRequest(false);
      navigate("/home");
    }
  }, [timer, showRequest, navigate]);

  const handleAccept = () => {
    setShowRequest(false);
    navigate("/pickup-navigation");
  };

  const handleReject = () => {
    setShowRequest(false);
    navigate("/home");
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] relative">
      {/* Map Background */}
      <div className="absolute inset-0">
        <MapView className="w-full h-full" showRoute={true} />
      </div>

      {/* Timer Badge */}
      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        className="absolute top-8 left-1/2 -translate-x-1/2 z-20"
      >
        <div className="bg-[#EF4444] text-white px-6 py-3 rounded-full font-bold text-lg shadow-xl flex items-center gap-2">
          <Clock className="w-5 h-5" />
          {timer}s
        </div>
      </motion.div>

      {/* Ride Request Bottom Sheet */}
      <BottomSheet isOpen={showRequest} onClose={handleReject}>
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="py-4"
        >
          {/* Header */}
          <div className="flex items-center justify-between mb-8">
            <h2 className="text-2xl font-bold text-white">New Ride Request</h2>
            <motion.div
              animate={{ scale: [1, 1.2, 1] }}
              transition={{ duration: 1, repeat: Infinity }}
              className="w-3 h-3 bg-[#22C55E] rounded-full"
            />
          </div>

          {/* Ride Details */}
          <div className="space-y-6 mb-8">
            {/* Pickup Location */}
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-[#22C55E] rounded-2xl flex items-center justify-center flex-shrink-0">
                <MapPin className="w-6 h-6 text-white" />
              </div>
              <div className="flex-1">
                <p className="text-[#94A3B8] text-sm mb-1">Pickup Location</p>
                <p className="text-white font-semibold text-lg">
                  MG Road, Brigade Road Junction
                </p>
                <p className="text-[#94A3B8] text-sm mt-1">2.3 km away</p>
              </div>
            </div>

            {/* Route Line */}
            <div className="ml-6 border-l-2 border-dashed border-[#94A3B8] h-8" />

            {/* Drop Location */}
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-[#D4AF37] rounded-2xl flex items-center justify-center flex-shrink-0">
                <Navigation className="w-6 h-6 text-[#0F1C2E]" />
              </div>
              <div className="flex-1">
                <p className="text-[#94A3B8] text-sm mb-1">Drop Location</p>
                <p className="text-white font-semibold text-lg">
                  Koramangala, 5th Block
                </p>
                <p className="text-[#94A3B8] text-sm mt-1">8.5 km trip</p>
              </div>
            </div>
          </div>

          {/* Earnings Card */}
          <div className="bg-gradient-to-r from-[#D4AF37] to-[#F4D03F] rounded-3xl p-6 mb-8">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-[#0F1C2E]/70 text-sm mb-1">Estimated Earnings</p>
                <h3 className="text-[#0F1C2E] text-3xl font-bold">₹185</h3>
              </div>
              <DollarSign className="w-12 h-12 text-[#0F1C2E]/30" />
            </div>
          </div>

          {/* Action Buttons */}
          <div className="grid grid-cols-2 gap-4">
            <DriverButton
              variant="error"
              onClick={handleReject}
              className="text-base"
            >
              Reject
            </DriverButton>
            <DriverButton
              variant="success"
              onClick={handleAccept}
              className="text-base"
            >
              Accept
            </DriverButton>
          </div>

          {/* Additional Info */}
          <div className="mt-6 p-4 bg-[#0F1C2E]/50 rounded-2xl">
            <div className="flex items-center justify-between text-sm">
              <span className="text-[#94A3B8]">Ride Type</span>
              <span className="text-white font-semibold">Economy</span>
            </div>
            <div className="flex items-center justify-between text-sm mt-2">
              <span className="text-[#94A3B8]">Payment Mode</span>
              <span className="text-white font-semibold">Online</span>
            </div>
          </div>
        </motion.div>
      </BottomSheet>
    </div>
  );
}
