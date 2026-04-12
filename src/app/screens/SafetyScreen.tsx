import { useState } from "react";
import { useNavigate } from "react-router";
import { motion } from "motion/react";
import { ArrowLeft, AlertCircle, Phone, MapPin, Share2, Shield } from "lucide-react";
import { GlassCard } from "../components/GlassCard";
import { DriverButton } from "../components/DriverButton";

export function SafetyScreen() {
  const navigate = useNavigate();
  const [sosActive, setSosActive] = useState(false);

  const handleSOS = () => {
    setSosActive(true);
    // In production, this would trigger emergency services
    setTimeout(() => setSosActive(false), 5000);
  };

  const emergencyContacts = [
    { name: "Emergency Helpline", number: "112" },
    { name: "Support Team", number: "1800-XXX-XXXX" },
    { name: "Local Police", number: "100" },
  ];

  const safetyFeatures = [
    {
      icon: MapPin,
      title: "Share Live Location",
      description: "Share your real-time location with trusted contacts",
      action: "Share Now",
    },
    {
      icon: Shield,
      title: "Trip Monitoring",
      description: "AI-powered monitoring for unusual route deviations",
      action: "Active",
    },
    {
      icon: Phone,
      title: "Emergency Contacts",
      description: "Quick access to emergency numbers",
      action: "View",
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
        <h2 className="text-2xl font-bold text-white">Safety Center</h2>
      </div>

      {/* SOS Button */}
      <motion.div
        initial={{ scale: 0, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        className="mb-12"
      >
        <GlassCard className="text-center">
          <h3 className="text-white text-xl font-bold mb-4">Emergency SOS</h3>
          <p className="text-[#94A3B8] mb-8">
            Press and hold for 3 seconds to alert emergency services
          </p>
          
          <motion.button
            onMouseDown={handleSOS}
            whileTap={{ scale: 0.9 }}
            animate={sosActive ? { scale: [1, 1.1, 1] } : {}}
            transition={{ duration: 0.3, repeat: sosActive ? Infinity : 0 }}
            className={`w-48 h-48 mx-auto rounded-full flex items-center justify-center shadow-2xl transition-all ${
              sosActive
                ? "bg-[#EF4444] shadow-[#EF4444]/60"
                : "bg-gradient-to-br from-[#EF4444] to-[#DC2626] shadow-[#EF4444]/40"
            }`}
          >
            <div className="text-center">
              <AlertCircle className="w-24 h-24 text-white mx-auto mb-2" />
              <span className="text-white text-xl font-bold">
                {sosActive ? "ALERTING..." : "SOS"}
              </span>
            </div>
          </motion.button>

          {sosActive && (
            <motion.p
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-[#EF4444] font-semibold mt-6"
            >
              Emergency services have been notified
            </motion.p>
          )}
        </GlassCard>
      </motion.div>

      {/* Safety Features */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.1 }}
        className="mb-8"
      >
        <h3 className="text-white text-xl font-bold mb-6">Safety Features</h3>
        <div className="space-y-4">
          {safetyFeatures.map((feature, index) => {
            const IconComponent = feature.icon;
            return (
              <motion.div
                key={index}
                initial={{ x: -20, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                transition={{ delay: 0.2 + index * 0.05 }}
              >
                <GlassCard className="cursor-pointer hover:border-[#D4AF37]/50 transition-colors">
                  <div className="flex items-center gap-4">
                    <div className="w-14 h-14 bg-[#D4AF37] rounded-2xl flex items-center justify-center flex-shrink-0">
                      <IconComponent className="w-7 h-7 text-[#0F1C2E]" />
                    </div>
                    <div className="flex-1">
                      <h4 className="text-white font-semibold mb-1">{feature.title}</h4>
                      <p className="text-[#94A3B8] text-sm">{feature.description}</p>
                    </div>
                    <button
                      className={`px-5 py-2 rounded-xl font-semibold text-sm transition-colors ${
                        feature.action === "Active"
                          ? "bg-[#22C55E] text-white"
                          : "bg-white/10 text-white hover:bg-white/20"
                      }`}
                    >
                      {feature.action}
                    </button>
                  </div>
                </GlassCard>
              </motion.div>
            );
          })}
        </div>
      </motion.div>

      {/* Emergency Contacts */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.3 }}
      >
        <h3 className="text-white text-xl font-bold mb-6">Emergency Contacts</h3>
        <div className="space-y-3">
          {emergencyContacts.map((contact, index) => (
            <motion.div
              key={index}
              initial={{ x: -20, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: 0.4 + index * 0.05 }}
            >
              <GlassCard className="p-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 bg-[#22C55E] rounded-xl flex items-center justify-center">
                      <Phone className="w-6 h-6 text-white" />
                    </div>
                    <div>
                      <h4 className="text-white font-semibold">{contact.name}</h4>
                      <p className="text-[#D4AF37] text-sm">{contact.number}</p>
                    </div>
                  </div>
                  <button className="w-12 h-12 bg-[#22C55E] rounded-xl flex items-center justify-center hover:bg-[#22C55E]/90 transition-colors">
                    <Phone className="w-5 h-5 text-white" />
                  </button>
                </div>
              </GlassCard>
            </motion.div>
          ))}
        </div>
      </motion.div>
    </div>
  );
}
