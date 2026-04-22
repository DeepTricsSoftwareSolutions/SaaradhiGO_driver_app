import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { ArrowLeft } from "lucide-react";
import { DriverButton } from "../components/DriverButton";
import { GlassCard } from "../components/GlassCard";

export function StartRideScreen() {
  const navigate = useNavigate();
  const [otp, setOtp] = useState("");

  const handleStartTrip = () => {
    if (otp === "1234") {
      navigate("/live-trip");
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] p-6">
      {/* Header */}
      <div className="flex items-center gap-4 mt-8 mb-12">
        <button
          onClick={() => navigate(-1)}
          className="w-12 h-12 bg-white/10 rounded-2xl flex items-center justify-center"
        >
          <ArrowLeft className="w-6 h-6 text-white" />
        </button>
        <h2 className="text-xl font-semibold text-white">Start Ride</h2>
      </div>

      {/* Rider Info */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="mb-8"
      >
        <GlassCard>
          <div className="flex items-center gap-4 mb-6">
            <div className="w-20 h-20 bg-gradient-to-br from-[#D4AF37] to-[#F4D03F] rounded-3xl flex items-center justify-center text-3xl font-bold text-[#0F1C2E]">
              RK
            </div>
            <div className="flex-1">
              <h3 className="text-white text-2xl font-bold">Rajesh Kumar</h3>
              <p className="text-[#94A3B8] text-lg">Verified Rider</p>
            </div>
          </div>
          
          <div className="space-y-3">
            <div className="flex justify-between text-sm">
              <span className="text-[#94A3B8]">Ride Type</span>
              <span className="text-white font-semibold">Economy</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-[#94A3B8]">Payment</span>
              <span className="text-white font-semibold">Cash</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-[#94A3B8]">Distance</span>
              <span className="text-white font-semibold">8.5 km</span>
            </div>
          </div>
        </GlassCard>
      </motion.div>

      {/* OTP Verification */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.2 }}
      >
        <GlassCard>
          <h3 className="text-white text-xl font-bold mb-4">Enter Ride OTP</h3>
          <p className="text-[#94A3B8] mb-6">
            Ask the rider for their 4-digit OTP to start the trip
          </p>
          
          <input
            type="tel"
            maxLength={4}
            value={otp}
            onChange={(e) => setOtp(e.target.value.replace(/\D/g, ""))}
            placeholder="Enter 4-digit OTP"
            className="w-full bg-[#0F1C2E]/50 border border-white/10 rounded-2xl px-6 py-5 text-white text-center text-2xl font-bold tracking-widest placeholder:text-[#94A3B8]/50 focus:outline-none focus:border-[#D4AF37] transition-colors mb-6"
          />

          <div className="bg-[#D4AF37]/10 border border-[#D4AF37]/30 rounded-2xl p-4 mb-6">
            <p className="text-[#D4AF37] text-sm text-center">
              Demo OTP: <span className="font-bold">1234</span>
            </p>
          </div>

          <DriverButton
            onClick={handleStartTrip}
            disabled={otp.length !== 4}
            variant="success"
            className="w-full"
          >
            Start Trip
          </DriverButton>
        </GlassCard>
      </motion.div>

      {/* Destination Preview */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.4 }}
        className="mt-8"
      >
        <div className="bg-[#1E3A5F]/40 backdrop-blur-xl border border-white/10 rounded-3xl p-6">
          <p className="text-[#94A3B8] text-sm mb-2">Destination</p>
          <p className="text-white font-semibold text-lg">
            Koramangala, 5th Block, Bangalore
          </p>
        </div>
      </motion.div>
    </div>
  );
}
