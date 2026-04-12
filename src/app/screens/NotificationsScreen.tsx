import { useNavigate } from "react-router";
import { motion } from "motion/react";
import { ArrowLeft, Bell, DollarSign, Star, AlertCircle, Settings } from "lucide-react";
import { GlassCard } from "../components/GlassCard";

export function NotificationsScreen() {
  const navigate = useNavigate();

  const notifications = [
    {
      id: 1,
      type: "ride",
      icon: Bell,
      title: "New Ride Request",
      message: "You have a new ride request from MG Road",
      time: "2 min ago",
      unread: true,
    },
    {
      id: 2,
      type: "earnings",
      icon: DollarSign,
      title: "Payment Received",
      message: "₹185 has been added to your wallet",
      time: "1 hour ago",
      unread: true,
    },
    {
      id: 3,
      type: "rating",
      icon: Star,
      title: "New 5-Star Rating",
      message: "Rajesh Kumar rated you 5 stars",
      time: "3 hours ago",
      unread: true,
    },
    {
      id: 4,
      type: "system",
      icon: Settings,
      title: "System Update",
      message: "New features are available. Update to v2.5.0",
      time: "5 hours ago",
      unread: false,
    },
    {
      id: 5,
      type: "earnings",
      icon: DollarSign,
      title: "Weekly Summary",
      message: "You earned ₹9,080 this week. Great job!",
      time: "Yesterday",
      unread: false,
    },
    {
      id: 6,
      type: "alert",
      icon: AlertCircle,
      title: "Document Expiry",
      message: "Your driving license expires in 30 days",
      time: "2 days ago",
      unread: false,
    },
  ];

  const getIconColor = (type: string) => {
    const colors = {
      ride: "bg-[#D4AF37]",
      earnings: "bg-[#22C55E]",
      rating: "bg-[#D4AF37]",
      system: "bg-[#3B82F6]",
      alert: "bg-[#EF4444]",
    };
    return colors[type as keyof typeof colors] || "bg-[#94A3B8]";
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] p-6">
      {/* Header */}
      <div className="flex items-center justify-between mt-8 mb-12">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate(-1)}
            className="w-12 h-12 bg-white/10 rounded-2xl flex items-center justify-center"
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </button>
          <h2 className="text-2xl font-bold text-white">Notifications</h2>
        </div>
        <button className="text-[#D4AF37] text-sm font-semibold">Mark all read</button>
      </div>

      {/* Notifications List */}
      <div className="space-y-4">
        {notifications.map((notification, index) => {
          const IconComponent = notification.icon;
          return (
            <motion.div
              key={notification.id}
              initial={{ x: -20, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: index * 0.05 }}
            >
              <GlassCard
                className={`cursor-pointer hover:border-[#D4AF37]/50 transition-all ${
                  notification.unread ? "border-[#D4AF37]/30" : ""
                }`}
              >
                <div className="flex items-start gap-4">
                  <div
                    className={`w-12 h-12 ${getIconColor(
                      notification.type
                    )} rounded-2xl flex items-center justify-center flex-shrink-0`}
                  >
                    <IconComponent
                      className={`w-6 h-6 ${
                        notification.type === "earnings" || notification.type === "rating"
                          ? "text-white"
                          : "text-[#0F1C2E]"
                      }`}
                    />
                  </div>
                  <div className="flex-1">
                    <div className="flex items-start justify-between mb-1">
                      <h3 className="text-white font-semibold">{notification.title}</h3>
                      {notification.unread && (
                        <div className="w-2 h-2 bg-[#D4AF37] rounded-full" />
                      )}
                    </div>
                    <p className="text-[#94A3B8] text-sm mb-2 leading-relaxed">
                      {notification.message}
                    </p>
                    <span className="text-[#94A3B8] text-xs">{notification.time}</span>
                  </div>
                </div>
              </GlassCard>
            </motion.div>
          );
        })}
      </div>

      {/* Empty state if no notifications */}
      {notifications.length === 0 && (
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="text-center py-20"
        >
          <div className="w-24 h-24 bg-[#1E3A5F] rounded-full flex items-center justify-center mx-auto mb-6">
            <Bell className="w-12 h-12 text-[#94A3B8]" />
          </div>
          <h3 className="text-white text-xl font-bold mb-2">No Notifications</h3>
          <p className="text-[#94A3B8]">You're all caught up!</p>
        </motion.div>
      )}
    </div>
  );
}
