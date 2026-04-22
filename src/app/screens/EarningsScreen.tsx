import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { ArrowLeft, TrendingUp, Wallet, Calendar } from "lucide-react";
import { GlassCard } from "../components/GlassCard";
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";
import { apiClient } from "../lib/api";

export function EarningsScreen() {
  const navigate = useNavigate();
  const [period, setPeriod] = useState<"daily" | "weekly" | "monthly">("weekly");
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchEarnings();
  }, []);

  const fetchEarnings = async () => {
    try {
      const data = await apiClient.get("/earnings");
      setStats(data);
    } catch (err) {
      console.error("Failed to fetch earnings", err);
    } finally {
      setLoading(false);
    }
  };

  const weeklyData = [
    { day: "Mon", earnings: 850 },
    { day: "Tue", earnings: 1200 },
    { day: "Wed", earnings: 980 },
    { day: "Thu", earnings: 1450 },
    { day: "Fri", earnings: 1650 },
    { day: "Sat", earnings: 2100 },
    { day: "Sun", earnings: 1850 },
  ];

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
          <h2 className="text-2xl font-bold text-white">Earnings</h2>
        </div>
        <button
          onClick={() => navigate("/wallet")}
          className="w-12 h-12 bg-[#D4AF37] rounded-2xl flex items-center justify-center shadow-lg shadow-[#D4AF37]/30"
        >
          <Wallet className="w-6 h-6 text-[#0F1C2E]" />
        </button>
      </div>

      {/* Total Earnings Card */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="mb-8"
      >
        <GlassCard className="bg-gradient-to-br from-[#D4AF37]/20 to-[#F4D03F]/20 border-[#D4AF37]/30">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-[#94A3B8] text-sm mb-2">This Week's Earnings</p>
              <h1 className="text-5xl font-bold text-[#D4AF37]">₹{(stats?.week || 0).toLocaleString()}</h1>
            </div>
            <div className="w-16 h-16 bg-[#D4AF37] rounded-2xl flex items-center justify-center">
              <TrendingUp className="w-8 h-8 text-[#0F1C2E]" />
            </div>
          </div>
          <div className="flex items-center gap-2 text-[#22C55E]">
            <TrendingUp className="w-4 h-4" />
            <span className="text-sm font-semibold">+23% from last week</span>
          </div>
        </GlassCard>
      </motion.div>

      {/* Period Selector */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.1 }}
        className="flex gap-3 mb-8"
      >
        {(["daily", "weekly", "monthly"] as const).map((p) => (
          <button
            key={p}
            onClick={() => setPeriod(p)}
            className={`flex-1 py-3 rounded-2xl font-semibold text-sm transition-all ${
              period === p
                ? "bg-[#D4AF37] text-[#0F1C2E]"
                : "bg-white/10 text-[#94A3B8] hover:bg-white/20"
            }`}
          >
            {p.charAt(0).toUpperCase() + p.slice(1)}
          </button>
        ))}
      </motion.div>

      {/* Chart */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="mb-8"
      >
        <GlassCard>
          <h3 className="text-white text-lg font-bold mb-6">Earnings Trend</h3>
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={weeklyData}>
              <defs>
                <linearGradient id="colorEarnings" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#D4AF37" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#D4AF37" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#94A3B8" opacity={0.1} />
              <XAxis dataKey="day" stroke="#94A3B8" />
              <YAxis stroke="#94A3B8" />
              <Tooltip
                contentStyle={{
                  backgroundColor: "#1E3A5F",
                  border: "1px solid rgba(255,255,255,0.1)",
                  borderRadius: "16px",
                  color: "#FFFFFF",
                }}
              />
              <Area
                type="monotone"
                dataKey="earnings"
                stroke="#D4AF37"
                strokeWidth={3}
                fill="url(#colorEarnings)"
              />
            </AreaChart>
          </ResponsiveContainer>
        </GlassCard>
      </motion.div>

      {/* Stats Grid */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.3 }}
        className="grid grid-cols-2 gap-4 mb-8"
      >
        <GlassCard>
          <p className="text-[#94A3B8] text-sm mb-2">Today</p>
          <h3 className="text-white text-2xl font-bold">₹{stats?.today || 0}</h3>
        </GlassCard>
        <GlassCard>
          <p className="text-[#94A3B8] text-sm mb-2">This Month</p>
          <h3 className="text-white text-2xl font-bold">₹{(stats?.month || 0).toLocaleString()}</h3>
        </GlassCard>
        <GlassCard>
          <p className="text-[#94A3B8] text-sm mb-2">Total Rides</p>
          <h3 className="text-white text-2xl font-bold">{stats?.totalRides || 0}</h3>
        </GlassCard>
        <GlassCard>
          <p className="text-[#94A3B8] text-sm mb-2">Avg / Ride</p>
          <h3 className="text-white text-2xl font-bold">
            ₹{stats?.totalRides > 0 ? Math.round((stats?.total || 0) / stats?.totalRides) : 0}
          </h3>
        </GlassCard>
      </motion.div>
    </div>
  );
}
