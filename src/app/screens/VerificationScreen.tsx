import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { Clock, CheckCircle } from "lucide-react";
import { DriverButton } from "../components/DriverButton";
import { StatusBadge } from "../components/StatusBadge";

export function VerificationScreen() {
  const navigate = useNavigate();

  useEffect(() => {
    // Auto-navigate after 5 seconds (simulating verification)
    const timer = setTimeout(() => {
      navigate("/home");
    }, 5000);
    return () => clearTimeout(timer);
  }, [navigate]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] p-6 flex flex-col items-center justify-center">
      {/* Animated Icon */}
      <motion.div
        animate={{ 
          rotate: [0, 360],
          scale: [1, 1.1, 1]
        }}
        transition={{ 
          rotate: { duration: 3, repeat: Infinity, ease: "linear" },
          scale: { duration: 2, repeat: Infinity }
        }}
        className="w-32 h-32 mb-8"
      >
        <div className="w-full h-full bg-gradient-to-br from-[#D4AF37] to-[#F4D03F] rounded-full flex items-center justify-center shadow-2xl shadow-[#D4AF37]/50">
          <Clock className="w-16 h-16 text-[#0F1C2E]" />
        </div>
      </motion.div>

      {/* Status Badge */}
      <StatusBadge status="pending" className="mb-6" />

      {/* Content */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.3 }}
        className="text-center max-w-md"
      >
        <h1 className="text-3xl font-bold text-white mb-4">
          Verification in Progress
        </h1>
        <p className="text-[#94A3B8] text-lg leading-relaxed mb-8">
          We're reviewing your documents. This usually takes 24-48 hours. We'll notify you once approved.
        </p>

        {/* Timeline */}
        <div className="bg-[#1E3A5F]/40 backdrop-blur-xl border border-white/10 rounded-3xl p-6 text-left space-y-4 mb-8">
          <div className="flex items-center gap-4">
            <div className="w-10 h-10 bg-[#22C55E] rounded-full flex items-center justify-center">
              <CheckCircle className="w-6 h-6 text-white" />
            </div>
            <div>
              <p className="text-white font-semibold">Documents Received</p>
              <p className="text-[#94A3B8] text-sm">Just now</p>
            </div>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="w-10 h-10 bg-[#D4AF37] rounded-full flex items-center justify-center">
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
              >
                <Clock className="w-6 h-6 text-[#0F1C2E]" />
              </motion.div>
            </div>
            <div>
              <p className="text-white font-semibold">Verification</p>
              <p className="text-[#94A3B8] text-sm">In progress...</p>
            </div>
          </div>
          
          <div className="flex items-center gap-4 opacity-40">
            <div className="w-10 h-10 bg-[#94A3B8] rounded-full flex items-center justify-center">
              <CheckCircle className="w-6 h-6 text-white" />
            </div>
            <div>
              <p className="text-white font-semibold">Approval</p>
              <p className="text-[#94A3B8] text-sm">Pending</p>
            </div>
          </div>
        </div>

        <DriverButton
          onClick={() => navigate("/home")}
          variant="secondary"
          className="w-full"
        >
          Continue to Dashboard
        </DriverButton>
      </motion.div>
    </div>
  );
}
