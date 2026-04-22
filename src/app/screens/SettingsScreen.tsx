import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { ArrowLeft, User, Bell, Lock, HelpCircle, LogOut, ChevronRight } from "lucide-react";
import { GlassCard } from "../components/GlassCard";
import { apiClient } from "../lib/api";

export function SettingsScreen() {
  const navigate = useNavigate();
  const [profile, setProfile] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    try {
      const data = await apiClient.get("/driver/profile");
      setProfile(data);
    } catch (err) {
      console.error("Failed to fetch profile", err);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = () => {
    localStorage.clear();
    navigate("/splash");
  };

  const settingsSections = [
    {
      title: "Account",
      items: [
        { icon: User, label: "Edit Profile", path: "/profile" },
        { icon: Lock, label: "Privacy & Security", path: "/privacy" },
        { icon: Bell, label: "Notifications", path: "/notifications" },
      ],
    },
    {
      title: "Support",
      items: [
        { icon: HelpCircle, label: "Help Center", path: "/help" },
      ],
    },
  ];

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
        <h2 className="text-2xl font-bold text-white">Settings</h2>
      </div>

      {/* Profile Card */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="mb-8"
      >
        <GlassCard>
          <div className="flex items-center gap-4">
            <div className="w-20 h-20 bg-gradient-to-br from-[#D4AF37] to-[#F4D03F] rounded-3xl flex items-center justify-center text-3xl font-bold text-[#0F1C2E]">
              {profile?.name ? profile.name.split(" ").map((n: string) => n[0]).join("").toUpperCase() : "..."}
            </div>
            <div className="flex-1">
              <h3 className="text-white text-xl font-bold mb-1">{profile?.name || "Loading..."}</h3>
              <p className="text-[#94A3B8]">{profile?.phone}</p>
              <div className="flex items-center gap-2 mt-2">
                <div className={`px-3 py-1 ${profile?.status === 'APPROVED' ? 'bg-[#22C55E]/20 border-[#22C55E]/30' : 'bg-white/10 border-white/20'} rounded-full`}>
                  <span className={`${profile?.status === 'APPROVED' ? 'text-[#22C55E]' : 'text-white'} text-xs font-semibold`}>
                    {profile?.status || "Pending"}
                  </span>
                </div>
                <div className="px-3 py-1 bg-[#D4AF37]/20 border border-[#D4AF37]/30 rounded-full">
                  <span className="text-[#D4AF37] text-xs font-semibold">{profile?.rating || 5.0} ★</span>
                </div>
              </div>
            </div>
          </div>
        </GlassCard>
      </motion.div>

      {/* Settings Sections */}
      {settingsSections.map((section, sectionIndex) => (
        <motion.div
          key={sectionIndex}
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.1 + sectionIndex * 0.1 }}
          className="mb-8"
        >
          <h3 className="text-white text-lg font-bold mb-4">{section.title}</h3>
          <div className="space-y-3">
            {section.items.map((item, index) => {
              const IconComponent = item.icon;
              return (
                <motion.div
                  key={index}
                  initial={{ x: -20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: 0.2 + sectionIndex * 0.1 + index * 0.05 }}
                >
                  <GlassCard className="p-4 cursor-pointer hover:border-[#D4AF37]/50 transition-colors">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 bg-[#D4AF37] rounded-xl flex items-center justify-center">
                          <IconComponent className="w-6 h-6 text-[#0F1C2E]" />
                        </div>
                        <span className="text-white font-semibold">{item.label}</span>
                      </div>
                      <ChevronRight className="w-5 h-5 text-[#94A3B8]" />
                    </div>
                  </GlassCard>
                </motion.div>
              );
            })}
          </div>
        </motion.div>
      ))}

      {/* Logout */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.4 }}
      >
        <button
          onClick={handleLogout}
          className="w-full bg-[#EF4444]/20 hover:bg-[#EF4444]/30 border border-[#EF4444]/30 text-[#EF4444] font-semibold rounded-2xl p-5 flex items-center justify-center gap-3 transition-colors"
        >
          <LogOut className="w-5 h-5" />
          Log Out
        </button>
      </motion.div>

      {/* App Version */}
      <p className="text-[#94A3B8] text-center text-sm mt-8">
        SaaradhiGO Driver v2.5.0
      </p>
    </div>
  );
}