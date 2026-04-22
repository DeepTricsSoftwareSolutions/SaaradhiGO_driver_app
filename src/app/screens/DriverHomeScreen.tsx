import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { Menu, Wallet, Bell, Settings } from "lucide-react";
import { MapView } from "../components/MapView";
import { StatusBadge } from "../components/StatusBadge";
import { GlassCard } from "../components/GlassCard";
import { DriverButton } from "../components/DriverButton";
import { BottomSheet } from "../components/BottomSheet";
import { apiClient } from "../lib/api";

export function DriverHomeScreen() {
  const navigate = useNavigate();
  const [profile, setProfile] = useState<any>(null);
  const [isOnline, setIsOnline] = useState(false);
  const [showMenu, setShowMenu] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    try {
      const data = await apiClient.get("/driver/profile");
      setProfile(data);
      setIsOnline(data.isOnline);
    } catch (err) {
      console.error("Failed to fetch profile", err);
    } finally {
      setLoading(false);
    }
  };

  const toggleStatus = async () => {
    try {
      const newStatus = !isOnline;
      await apiClient.patch("/driver/status", { isOnline: newStatus });
      setIsOnline(newStatus);
    } catch (err) {
      console.error("Failed to update status", err);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] relative">
      {/* Map Background */}
      <div className="absolute inset-0">
        <MapView className="w-full h-full" />
      </div>

      {loading && (
        <div className="absolute inset-0 z-50 bg-[#0F1C2E]/50 backdrop-blur-md flex items-center justify-center">
          <div className="w-12 h-12 border-4 border-[#D4AF37] border-t-transparent rounded-full animate-spin"></div>
        </div>
      )}

      {/* Top Bar */}
      <div className="relative z-10 p-6">
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="flex items-center justify-between"
        >
          <button
            onClick={() => setShowMenu(true)}
            className="w-12 h-12 bg-[#1E3A5F]/80 backdrop-blur-xl rounded-2xl flex items-center justify-center border border-white/10 shadow-xl"
          >
            <Menu className="w-6 h-6 text-white" />
          </button>

          <StatusBadge status={isOnline ? "online" : "offline"} />

          <button
            onClick={() => navigate("/notifications")}
            className="w-12 h-12 bg-[#1E3A5F]/80 backdrop-blur-xl rounded-2xl flex items-center justify-center border border-white/10 shadow-xl relative"
          >
            <Bell className="w-6 h-6 text-white" />
            <div className="absolute -top-1 -right-1 w-5 h-5 bg-[#EF4444] rounded-full flex items-center justify-center">
              <span className="text-white text-xs font-bold">3</span>
            </div>
          </button>
        </motion.div>

        {/* Earnings Card */}
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="mt-6"
        >
          <GlassCard className="backdrop-blur-2xl">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-[#94A3B8] text-sm mb-1">Total Balance</p>
                <h2 className="text-3xl font-bold text-[#D4AF37]">
                  ₹{profile?.today || profile?.walletBalance || 0}
                </h2>
              </div>
              <button
                onClick={() => navigate("/earnings")}
                className="w-14 h-14 bg-[#D4AF37] rounded-2xl flex items-center justify-center shadow-lg shadow-[#D4AF37]/30"
              >
                <Wallet className="w-7 h-7 text-[#0F1C2E]" />
              </button>
            </div>
          </GlassCard>
        </motion.div>
      </div>

      {/* Bottom Toggle */}
      <motion.div
        initial={{ y: 100, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.4 }}
        className="absolute bottom-0 left-0 right-0 p-6"
      >
        <div className="bg-[#1E3A5F]/90 backdrop-blur-2xl border border-white/10 rounded-3xl p-8 shadow-2xl">
          <div className="text-center mb-6">
            <h3 className="text-white text-xl font-bold mb-2">
              {isOnline ? "You're Online" : "You're Offline"}
            </h3>
            <p className="text-[#94A3B8]">
              {isOnline 
                ? "Ready to accept ride requests" 
                : "Go online to start receiving rides"}
            </p>
          </div>

          <DriverButton
            variant={isOnline ? "error" : "success"}
            onClick={toggleStatus}
            className="w-full text-xl py-7"
          >
            {isOnline ? "Go Offline" : "Go Online"}
          </DriverButton>
        </div>
      </motion.div>

      {/* Menu Bottom Sheet */}
      <BottomSheet isOpen={showMenu} onClose={() => setShowMenu(false)}>
        <div className="py-4">
          <h2 className="text-2xl font-bold text-white mb-8">Menu</h2>
          
          <div className="space-y-3">
            {[
              { icon: Wallet, label: "Earnings", path: "/earnings" },
              { icon: Settings, label: "Wallet", path: "/wallet" },
              { icon: Menu, label: "Ride History", path: "/history" },
              { icon: Menu, label: "Ratings & Reviews", path: "/ratings" },
              { icon: Settings, label: "Safety", path: "/safety" },
              { icon: Settings, label: "Settings", path: "/settings" },
            ].map((item, i) => (
              <motion.button
                key={i}
                initial={{ x: -20, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                transition={{ delay: i * 0.05 }}
                onClick={() => {
                  setShowMenu(false);
                  navigate(item.path);
                }}
                className="w-full bg-[#0F1C2E]/50 hover:bg-[#0F1C2E]/70 border border-white/10 rounded-2xl p-5 flex items-center gap-4 transition-all"
              >
                <div className="w-12 h-12 bg-[#D4AF37] rounded-xl flex items-center justify-center">
                  <item.icon className="w-6 h-6 text-[#0F1C2E]" />
                </div>
                <span className="text-white font-semibold text-lg">{item.label}</span>
              </motion.button>
            ))}
          </div>
        </div>
      </BottomSheet>
    </div>
  );
}
