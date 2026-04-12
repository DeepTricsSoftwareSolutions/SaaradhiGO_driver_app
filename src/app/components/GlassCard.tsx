import { motion } from "motion/react";
import { ReactNode } from "react";

interface GlassCardProps {
  children: ReactNode;
  className?: string;
}

export function GlassCard({ children, className = "" }: GlassCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className={`bg-[#1E3A5F]/40 backdrop-blur-xl border border-white/10 rounded-3xl p-6 shadow-2xl ${className}`}
    >
      {children}
    </motion.div>
  );
}
