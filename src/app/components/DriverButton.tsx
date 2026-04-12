import { motion, HTMLMotionProps } from "motion/react";
import { ReactNode } from "react";

interface DriverButtonProps extends Omit<HTMLMotionProps<"button">, 'size' | 'variants'> {
  variant?: "primary" | "secondary" | "success" | "error" | "disabled";
  size?: "sm" | "md" | "lg";
  children: ReactNode;
}

export function DriverButton({
  variant = "primary",
  size = "lg",
  children,
  disabled,
  className = "",
  ...props
}: DriverButtonProps) {
  const baseClasses = "rounded-2xl font-semibold transition-all duration-200 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed";
  
  const variantClasses = {
    primary: "bg-[#D4AF37] text-[#0F1C2E] shadow-lg shadow-[#D4AF37]/30",
    secondary: "bg-[#1E3A5F] text-white border border-[#D4AF37]/30",
    success: "bg-[#22C55E] text-white shadow-lg shadow-[#22C55E]/30",
    error: "bg-[#EF4444] text-white shadow-lg shadow-[#EF4444]/30",
    disabled: "bg-[#2A4A6F] text-[#94A3B8]",
  };
  
  const sizeClasses = {
    sm: "px-6 py-3 text-sm",
    md: "px-8 py-4 text-base",
    lg: "px-10 py-5 text-lg",
  };

  const appliedVariant = disabled ? "disabled" : variant;

  return (
    <motion.button
      whileTap={disabled ? {} : { scale: 0.95 }}
      className={`${baseClasses} ${variantClasses[appliedVariant]} ${sizeClasses[size]} ${className}`}
      disabled={disabled}
      {...props}
    >
      {children}
    </motion.button>
  );
}
