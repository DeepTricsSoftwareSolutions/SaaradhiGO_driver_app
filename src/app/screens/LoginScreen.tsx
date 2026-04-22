import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { Phone, ArrowRight } from "lucide-react";
import { DriverButton } from "../components/DriverButton";
import { GlassCard } from "../components/GlassCard";
import { apiClient } from "../lib/api";

export function LoginScreen() {
  const navigate = useNavigate();
  const [phone, setPhone] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  const handleContinue = async () => {
    if (phone.length === 10) {
      setIsLoading(true);
      setError("");
      try {
        await apiClient.post("/auth/send-otp", { phone });
        localStorage.setItem("pendingPhone", phone);
        navigate("/otp");
      } catch (err: any) {
        setError(err.message || "Failed to send OTP. Please try again.");
      } finally {
        setIsLoading(false);
      }
    } else {
      setError("Please enter a valid 10-digit phone number");
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] p-6 flex flex-col">
      {/* Logo */}
      <motion.div
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="mt-12 mb-16"
      >
        <div className="w-16 h-16 bg-gradient-to-br from-[#D4AF37] to-[#F4D03F] rounded-2xl flex items-center justify-center shadow-xl">
          <span className="text-3xl font-bold text-[#0F1C2E]">S</span>
        </div>
      </motion.div>

      {/* Content */}
      <div className="flex-1 flex flex-col justify-center">
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.2 }}
        >
          <h1 className="text-3xl font-bold text-white mb-3">
            Welcome Back
          </h1>
          <p className="text-[#94A3B8] text-lg mb-12">
            Enter your phone number to continue
          </p>

          <GlassCard>
            <div className="space-y-6">
              {/* Phone Input */}
              <div>
                <label className="text-white text-sm mb-2 block">
                  Phone Number
                </label>
                <div className="relative">
                  <Phone className="absolute left-4 top-1/2 -translate-y-1/2 text-[#94A3B8] w-5 h-5" />
                  <input
                    type="tel"
                    maxLength={10}
                    value={phone}
                    onChange={(e) => {
                      setPhone(e.target.value.replace(/\D/g, ""));
                      setError("");
                    }}
                    placeholder="10-digit mobile number"
                    className="w-full bg-[#0F1C2E]/50 border border-white/10 rounded-2xl pl-12 pr-4 py-5 text-white placeholder:text-[#94A3B8]/50 focus:outline-none focus:border-[#D4AF37] transition-colors"
                  />
                </div>
                {error && (
                  <motion.p
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="text-[#EF4444] text-sm mt-2"
                  >
                    {error}
                  </motion.p>
                )}
              </div>

              {/* Continue Button */}
              <DriverButton
                onClick={handleContinue}
                disabled={isLoading}
                className="w-full flex items-center justify-center gap-2"
              >
                {isLoading ? "Sending OTP..." : "Continue"}
                {!isLoading && <ArrowRight className="w-5 h-5" />}
              </DriverButton>
            </div>
          </GlassCard>

          {/* Terms */}
          <p className="text-[#94A3B8] text-xs text-center mt-8 leading-relaxed">
            By continuing, you agree to our Terms of Service and Privacy Policy
          </p>
        </motion.div>
      </div>
    </div>
  );
}
