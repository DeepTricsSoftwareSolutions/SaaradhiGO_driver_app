import { motion } from "motion/react";
import { useNavigate } from "react-router";
import { 
  Smartphone, 
  LogIn, 
  Shield, 
  Upload, 
  CheckCircle, 
  Home, 
  Bell, 
  Navigation, 
  Play, 
  MapPin,
  DollarSign,
  Wallet,
  History,
  Star,
  AlertCircle,
  Settings,
  Palette
} from "lucide-react";
import { GlassCard } from "../components/GlassCard";
import { DriverButton } from "../components/DriverButton";

export function NavigationGuideScreen() {
  const navigate = useNavigate();

  const screens = [
    { path: "/splash", icon: Smartphone, label: "Splash Screen", desc: "App launch animation" },
    { path: "/login", icon: LogIn, label: "Login", desc: "Phone number entry" },
    { path: "/otp", icon: Shield, label: "OTP Verification", desc: "6-digit code" },
    { path: "/onboarding", icon: Upload, label: "Document Upload", desc: "Aadhaar, License, RC" },
    { path: "/verification", icon: CheckCircle, label: "Verification Pending", desc: "Approval status" },
    { path: "/home", icon: Home, label: "Driver Home", desc: "Main dashboard (Map)" },
    { path: "/ride-request", icon: Bell, label: "Ride Request", desc: "New ride popup" },
    { path: "/pickup-navigation", icon: Navigation, label: "Pickup Navigation", desc: "Navigate to rider" },
    { path: "/start-ride", icon: Play, label: "Start Ride", desc: "Enter OTP" },
    { path: "/live-trip", icon: MapPin, label: "Live Trip", desc: "Active navigation" },
    { path: "/end-trip", icon: CheckCircle, label: "End Trip", desc: "Fare breakdown" },
    { path: "/earnings", icon: DollarSign, label: "Earnings Dashboard", desc: "Charts & stats" },
    { path: "/wallet", icon: Wallet, label: "Wallet", desc: "Balance & transactions" },
    { path: "/history", icon: History, label: "Ride History", desc: "Past rides" },
    { path: "/ratings", icon: Star, label: "Ratings & Reviews", desc: "Driver ratings" },
    { path: "/notifications", icon: Bell, label: "Notifications", desc: "Alerts & updates" },
    { path: "/safety", icon: AlertCircle, label: "Safety Center", desc: "SOS & emergency" },
    { path: "/settings", icon: Settings, label: "Settings", desc: "Profile & preferences" },
    { path: "/design-system", icon: Palette, label: "Design System", desc: "Colors & components" },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] p-6">
      {/* Header */}
      <motion.div
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="mt-8 mb-12 text-center"
      >
        <div className="w-24 h-24 mx-auto mb-6 bg-gradient-to-br from-[#D4AF37] to-[#F4D03F] rounded-3xl flex items-center justify-center shadow-2xl shadow-[#D4AF37]/50">
          <span className="text-5xl font-bold text-[#0F1C2E]">S</span>
        </div>
        <h1 className="text-3xl font-bold text-white mb-2">SaaradhiGO</h1>
        <p className="text-[#D4AF37] text-lg font-semibold mb-2">Driver App Navigation</p>
        <p className="text-[#94A3B8]">All {screens.length} screens ready to explore</p>
      </motion.div>

      {/* Quick Start */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.1 }}
        className="mb-8"
      >
        <GlassCard className="bg-gradient-to-r from-[#D4AF37]/20 to-[#F4D03F]/20 border-[#D4AF37]/30">
          <h3 className="text-white text-xl font-bold mb-4">🚀 Quick Start</h3>
          <div className="space-y-3">
            <DriverButton 
              onClick={() => navigate("/splash")}
              variant="primary"
              className="w-full"
            >
              Start from Beginning (Splash)
            </DriverButton>
            <DriverButton 
              onClick={() => navigate("/home")}
              variant="secondary"
              className="w-full"
            >
              Jump to Main Dashboard
            </DriverButton>
            <DriverButton 
              onClick={() => navigate("/design-system")}
              variant="secondary"
              className="w-full"
            >
              View Design System
            </DriverButton>
          </div>
        </GlassCard>
      </motion.div>

      {/* All Screens */}
      <h2 className="text-white text-2xl font-bold mb-6">All Screens ({screens.length})</h2>
      
      <div className="space-y-3 mb-20">
        {screens.map((screen, index) => {
          const IconComponent = screen.icon;
          return (
            <motion.div
              key={screen.path}
              initial={{ x: -20, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: index * 0.03 }}
            >
              <GlassCard 
                className="cursor-pointer hover:border-[#D4AF37]/50 transition-all active:scale-98"
                onClick={() => navigate(screen.path)}
              >
                <div className="flex items-center gap-4">
                  <div className="w-14 h-14 bg-[#D4AF37] rounded-2xl flex items-center justify-center flex-shrink-0">
                    <IconComponent className="w-7 h-7 text-[#0F1C2E]" />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-white font-semibold text-lg">{screen.label}</h3>
                    <p className="text-[#94A3B8] text-sm">{screen.desc}</p>
                  </div>
                  <div className="text-[#D4AF37] text-sm font-mono">
                    {index + 1}
                  </div>
                </div>
              </GlassCard>
            </motion.div>
          );
        })}
      </div>

      {/* Documentation */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.5 }}
        className="mb-8"
      >
        <GlassCard>
          <h3 className="text-white text-xl font-bold mb-4">📚 Documentation</h3>
          <div className="space-y-3 text-sm">
            <div>
              <p className="text-[#D4AF37] font-semibold mb-1">DRIVER_APP_GUIDE.md</p>
              <p className="text-[#94A3B8]">Complete implementation guide with all screens, features, and Flutter mapping</p>
            </div>
            <div className="h-px bg-white/10" />
            <div>
              <p className="text-[#D4AF37] font-semibold mb-1">COMPONENT_SHOWCASE.md</p>
              <p className="text-[#94A3B8]">Detailed component library reference with code examples and patterns</p>
            </div>
          </div>
        </GlassCard>
      </motion.div>

      {/* Tech Stack */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.6 }}
        className="mb-8"
      >
        <GlassCard>
          <h3 className="text-white text-xl font-bold mb-4">⚡ Tech Stack</h3>
          <div className="grid grid-cols-2 gap-3 text-sm">
            <div>
              <p className="text-[#D4AF37] font-semibold">React 18</p>
              <p className="text-[#94A3B8] text-xs">UI Framework</p>
            </div>
            <div>
              <p className="text-[#D4AF37] font-semibold">TypeScript</p>
              <p className="text-[#94A3B8] text-xs">Type Safety</p>
            </div>
            <div>
              <p className="text-[#D4AF37] font-semibold">Tailwind v4</p>
              <p className="text-[#94A3B8] text-xs">Styling</p>
            </div>
            <div>
              <p className="text-[#D4AF37] font-semibold">Motion</p>
              <p className="text-[#94A3B8] text-xs">Animations</p>
            </div>
            <div>
              <p className="text-[#D4AF37] font-semibold">React Router 7</p>
              <p className="text-[#94A3B8] text-xs">Navigation</p>
            </div>
            <div>
              <p className="text-[#D4AF37] font-semibold">Recharts</p>
              <p className="text-[#94A3B8] text-xs">Data Viz</p>
            </div>
          </div>
        </GlassCard>
      </motion.div>

      {/* Footer */}
      <div className="text-center pb-8">
        <p className="text-[#94A3B8] text-sm">
          Built with ❤️ for production-ready mobile experiences
        </p>
        <p className="text-[#D4AF37] text-xs mt-2">
          SaaradhiGO Driver v2.5.0
        </p>
      </div>
    </div>
  );
}