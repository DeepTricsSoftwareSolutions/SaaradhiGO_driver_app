import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { ArrowLeft, MapPin, Navigation, Calendar } from "lucide-react";
import { GlassCard } from "../components/GlassCard";
import { apiClient } from "../lib/api";

export function RideHistoryScreen() {
  const navigate = useNavigate();
  const [rides, setRides] = useState<any[]>([]);
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchHistory();
  }, []);

  const fetchHistory = async () => {
    try {
      const data = await apiClient.get("/rides/history");
      setRides(data.history);
      
      // Fetch profile for overall stats
      const profile = await apiClient.get("/driver/profile");
      setStats(profile);
    } catch (err) {
      console.error("Failed to fetch history", err);
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateStr: string) => {
    const d = new Date(dateStr);
    return d.toLocaleString('en-IN', { 
      day: 'numeric', 
      month: 'short', 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  };

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
        <h2 className="text-2xl font-bold text-white">Ride History</h2>
      </div>

      {/* Summary */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="mb-8"
      >
        <GlassCard>
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <p className="text-[#94A3B8] text-sm mb-1">Total Rides</p>
              <h3 className="text-white text-2xl font-bold">{stats?.totalRides || 0}</h3>
            </div>
            <div>
              <p className="text-[#94A3B8] text-sm mb-1">Total Km</p>
              <h3 className="text-white text-2xl font-bold">{Math.round(stats?.totalDistance || 0)}</h3>
            </div>
            <div>
              <p className="text-[#94A3B8] text-sm mb-1">Rating</p>
              <h3 className="text-[#D4AF37] text-2xl font-bold">{stats?.rating || 5} ★</h3>
            </div>
          </div>
        </GlassCard>
      </motion.div>

      {loading && (
        <div className="flex justify-center py-12">
          <div className="w-12 h-12 border-4 border-[#D4AF37] border-t-transparent rounded-full animate-spin"></div>
        </div>
      )}

      {!loading && rides.length === 0 && (
        <div className="text-center py-20">
          <p className="text-[#94A3B8]">No rides completed yet</p>
        </div>
      )}

      {/* Rides List */}
      <div className="space-y-4">
        {rides.map((ride, index) => (
          <motion.div
            key={ride.id}
            initial={{ x: -20, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            transition={{ delay: index * 0.1 }}
          >
            <GlassCard className="hover:border-[#D4AF37]/50 transition-colors cursor-pointer">
              {/* Ride ID & Date */}
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <Calendar className="w-4 h-4 text-[#D4AF37]" />
                  <span className="text-[#94A3B8] text-sm">{formatDate(ride.createdAt)}</span>
                </div>
                <span className="text-[#D4AF37] font-semibold text-sm truncate max-w-[100px]">
                  #{ride.id.split('-')[0]}
                </span>
              </div>

              {/* Route */}
              <div className="space-y-3 mb-4">
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 bg-[#22C55E] rounded-xl flex items-center justify-center flex-shrink-0">
                    <MapPin className="w-4 h-4 text-white" />
                  </div>
                  <div className="flex-1">
                    <p className="text-white font-semibold line-clamp-1">{ride.pickupAddr}</p>
                  </div>
                </div>

                <div className="ml-4 border-l-2 border-dashed border-[#94A3B8] h-4" />

                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 bg-[#D4AF37] rounded-xl flex items-center justify-center flex-shrink-0">
                    <Navigation className="w-4 h-4 text-[#0F1C2E]" />
                  </div>
                  <div className="flex-1">
                    <p className="text-white font-semibold line-clamp-1">{ride.dropAddr}</p>
                  </div>
                </div>
              </div>

              {/* Stats */}
              <div className="flex items-center justify-between pt-4 border-t border-white/10">
                <div className="flex gap-4">
                  <div>
                    <p className="text-[#94A3B8] text-xs">Distance</p>
                    <p className="text-white text-sm font-semibold">{ride.distanceKm} km</p>
                  </div>
                  <div>
                    <p className="text-[#94A3B8] text-xs">Duration</p>
                    <p className="text-white text-sm font-semibold">{ride.durationMin} min</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-[#D4AF37] text-2xl font-bold">₹{ride.fare}</p>
                  <div className="flex items-center gap-1 justify-end">
                    <span className="text-[#D4AF37] text-sm">
                      {"★".repeat(ride.riderRatingForDriver || 5)}
                    </span>
                  </div>
                </div>
              </div>
            </GlassCard>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
