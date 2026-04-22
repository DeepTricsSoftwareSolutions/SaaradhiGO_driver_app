import { useState, useRef, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { ArrowLeft } from "lucide-react";
import { DriverButton } from "../components/DriverButton";
import { GlassCard } from "../components/GlassCard";
import { apiClient } from "../lib/api";

export function OTPScreen() {
  const navigate = useNavigate();
  const [otp, setOtp] = useState(["", "", "", "", "", ""]);
  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);
  const [timer, setTimer] = useState(30);

  useEffect(() => {
    const interval = setInterval(() => {
      setTimer((prev) => (prev > 0 ? prev - 1 : 0));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  const handleChange = (index: number, value: string) => {
    if (value.length > 1) return;
    
    const newOtp = [...otp];
    newOtp[index] = value;
    setOtp(newOtp);

    // Auto-focus next input
    if (value && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent) => {
    if (e.key === "Backspace" && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [resendLoading, setResendLoading] = useState(false);
  const [infoMessage, setInfoMessage] = useState("");

  const handleVerify = async () => {
    const otpString = otp.join("");
    if (otpString.length === 6) {
      setIsLoading(true);
      setError("");
      try {
        const phone = localStorage.getItem("pendingPhone");
        if (!phone) {
          throw new Error("No phone number found. Please restart login.");
        }

        const res = await apiClient.post("/auth/verify-otp", { phone, otp: otpString });
        
        localStorage.setItem("token", res.token);
        localStorage.setItem("driverId", res.user.driverId);
        localStorage.setItem("userStatus", res.user.status);
        localStorage.removeItem("pendingPhone");

        if (res.user.status === "PENDING") {
          navigate("/onboarding");
        } else if (res.user.status === "VERIFYING") {
          navigate("/verification");
        } else {
          navigate("/home");
        }
      } catch (err: any) {
        setError(err.message || "Invalid OTP. Please try again.");
      } finally {
        setIsLoading(false);
      }
    }
  };

  const handleResend = async () => {
    const phone = localStorage.getItem("pendingPhone");
    if (!phone) {
      setError("No phone number found. Please restart login.");
      return;
    }

    setResendLoading(true);
    setError("");
    setInfoMessage("");
    try {
      const res = await apiClient.post("/auth/send-otp", { phone });
      setInfoMessage("OTP resent successfully. Please check your phone.");
      if (res.devOtp) {
        console.log("DEV OTP:", res.devOtp);
      }
      setTimer(30);
    } catch (err: any) {
      setError(err.message || "Failed to resend OTP. Please try again.");
    } finally {
      setResendLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] p-6">
      {/* Header */}
      <div className="flex items-center gap-4 mt-8 mb-16">
        <button
          onClick={() => navigate(-1)}
          className="w-12 h-12 bg-white/10 rounded-2xl flex items-center justify-center hover:bg-white/20 transition-colors"
        >
          <ArrowLeft className="w-6 h-6 text-white" />
        </button>
        <h2 className="text-xl font-semibold text-white">Verify OTP</h2>
      </div>

      {/* Content */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="max-w-md mx-auto"
      >
        <h1 className="text-3xl font-bold text-white mb-3">
          Enter OTP
        </h1>
        <p className="text-[#94A3B8] text-lg mb-12">
          We've sent a 6-digit code to your phone
        </p>

        <GlassCard>
          <div className="space-y-8">
            {/* OTP Inputs */}
            <div className="flex justify-between gap-3">
              {otp.map((digit, index) => (
                <input
                  key={index}
                  ref={(el) => (inputRefs.current[index] = el)}
                  type="tel"
                  maxLength={1}
                  value={digit}
                  onChange={(e) => handleChange(index, e.target.value)}
                  onKeyDown={(e) => handleKeyDown(index, e)}
                  className="w-14 h-16 bg-[#0F1C2E]/50 border border-white/10 rounded-2xl text-center text-2xl font-bold text-white focus:outline-none focus:border-[#D4AF37] transition-colors"
                />
              ))}
            </div>

            {/* Timer */}
            <div className="text-center">
              {timer > 0 ? (
                <p className="text-[#94A3B8] text-sm">
                  Resend code in <span className="text-[#D4AF37] font-semibold">{timer}s</span>
                </p>
              ) : (
                <button
                  onClick={handleResend}
                  disabled={resendLoading}
                  className="text-[#D4AF37] font-semibold text-sm hover:underline disabled:text-white/40"
                >
                  {resendLoading ? "Resending..." : "Resend OTP"}
                </button>
              )}
            </div>
            {infoMessage && (
              <p className="text-[#22C55E] text-sm mt-2">{infoMessage}</p>
            )}

            {error && (
              <motion.p
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-[#EF4444] text-sm text-center -mt-4 mb-2"
              >
                {error}
              </motion.p>
            )}

            {/* Verify Button */}
            <DriverButton
              onClick={handleVerify}
              disabled={otp.some((digit) => digit === "") || isLoading}
              className="w-full"
            >
              {isLoading ? "Verifying..." : "Verify & Continue"}
            </DriverButton>
          </div>
        </GlassCard>
      </motion.div>
    </div>
  );
}
