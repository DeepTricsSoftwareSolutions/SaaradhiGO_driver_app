import { motion } from "motion/react";
import { useEffect } from "react";
import { useNavigate } from "react-router";

export function SplashScreen() {
  const navigate = useNavigate();

  useEffect(() => {
    const timer = setTimeout(() => {
      navigate("/login");
    }, 3000);
    return () => clearTimeout(timer);
  }, [navigate]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] flex items-center justify-center overflow-hidden relative">
      {/* Animated background elements */}
      <motion.div
        animate={{
          scale: [1, 1.2, 1],
          opacity: [0.1, 0.2, 0.1],
        }}
        transition={{ duration: 4, repeat: Infinity }}
        className="absolute w-96 h-96 bg-[#D4AF37] rounded-full blur-[120px]"
      />
      
      {/* Logo */}
      <motion.div
        initial={{ scale: 0, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.8, type: "spring" }}
        className="text-center z-10"
      >
        <motion.div
          animate={{ rotate: [0, 360] }}
          transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
          className="w-32 h-32 mx-auto mb-6 bg-gradient-to-br from-[#D4AF37] to-[#F4D03F] rounded-3xl flex items-center justify-center shadow-2xl shadow-[#D4AF37]/50"
        >
          <span className="text-5xl font-bold text-[#0F1C2E]">S</span>
        </motion.div>
        
        <motion.h1
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.5 }}
          className="text-4xl font-bold text-white mb-2"
        >
          SaaradhiGO
        </motion.h1>
        
        <motion.p
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.7 }}
          className="text-[#D4AF37] text-lg font-semibold"
        >
          Driver Partner
        </motion.p>
        
        {/* Loading indicator */}
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: "100%" }}
          transition={{ duration: 2.5, delay: 0.5 }}
          className="h-1 bg-[#D4AF37] rounded-full mt-8 mx-auto max-w-xs"
        />
      </motion.div>
    </div>
  );
}