import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { ArrowLeft, Star, TrendingUp } from "lucide-react";
import { GlassCard } from "../components/GlassCard";

export function RatingsScreen() {
  const navigate = useNavigate();

  const overallRating = 4.8;
  const totalReviews = 234;

  const ratingBreakdown = [
    { stars: 5, count: 185, percentage: 79 },
    { stars: 4, count: 38, percentage: 16 },
    { stars: 3, count: 8, percentage: 3 },
    { stars: 2, count: 2, percentage: 1 },
    { stars: 1, count: 1, percentage: 1 },
  ];

  const reviews = [
    {
      id: 1,
      rider: "Rajesh Kumar",
      rating: 5,
      comment: "Excellent driver! Very professional and safe driving.",
      date: "2 hours ago",
    },
    {
      id: 2,
      rider: "Priya Sharma",
      rating: 4,
      comment: "Good service, reached on time.",
      date: "Yesterday",
    },
    {
      id: 3,
      rider: "Amit Patel",
      rating: 5,
      comment: "Very polite and helpful. Great experience!",
      date: "2 days ago",
    },
    {
      id: 4,
      rider: "Sneha Reddy",
      rating: 5,
      comment: "Best ride I've had. Highly recommended!",
      date: "3 days ago",
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
        <h2 className="text-2xl font-bold text-white">Ratings & Reviews</h2>
      </div>

      {/* Overall Rating */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="mb-8"
      >
        <GlassCard className="text-center">
          <div className="w-32 h-32 mx-auto mb-6 bg-gradient-to-br from-[#D4AF37] to-[#F4D03F] rounded-full flex items-center justify-center shadow-2xl shadow-[#D4AF37]/50">
            <div>
              <div className="text-5xl font-bold text-[#0F1C2E]">{overallRating}</div>
              <div className="flex justify-center mt-1">
                <Star className="w-6 h-6 text-[#0F1C2E] fill-[#0F1C2E]" />
              </div>
            </div>
          </div>
          <h3 className="text-white text-2xl font-bold mb-2">Excellent Rating</h3>
          <p className="text-[#94A3B8]">Based on {totalReviews} reviews</p>
          <div className="flex items-center justify-center gap-2 mt-4 text-[#22C55E]">
            <TrendingUp className="w-4 h-4" />
            <span className="text-sm font-semibold">+0.3 from last month</span>
          </div>
        </GlassCard>
      </motion.div>

      {/* Rating Breakdown */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.1 }}
        className="mb-8"
      >
        <GlassCard>
          <h3 className="text-white text-lg font-bold mb-6">Rating Breakdown</h3>
          <div className="space-y-4">
            {ratingBreakdown.map((item) => (
              <div key={item.stars} className="flex items-center gap-4">
                <div className="flex items-center gap-1 w-16">
                  <span className="text-white font-semibold">{item.stars}</span>
                  <Star className="w-4 h-4 text-[#D4AF37] fill-[#D4AF37]" />
                </div>
                <div className="flex-1">
                  <div className="h-3 bg-[#0F1C2E]/50 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-[#D4AF37] to-[#F4D03F]"
                      style={{ width: `${item.percentage}%` }}
                    />
                  </div>
                </div>
                <div className="w-16 text-right">
                  <span className="text-[#94A3B8] text-sm">{item.count}</span>
                </div>
              </div>
            ))}
          </div>
        </GlassCard>
      </motion.div>

      {/* Recent Reviews */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.2 }}
      >
        <h3 className="text-white text-xl font-bold mb-6">Recent Reviews</h3>
        <div className="space-y-4">
          {reviews.map((review, index) => (
            <motion.div
              key={review.id}
              initial={{ x: -20, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: 0.3 + index * 0.05 }}
            >
              <GlassCard className="p-5">
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <h4 className="text-white font-semibold mb-1">{review.rider}</h4>
                    <div className="flex items-center gap-1">
                      {[...Array(5)].map((_, i) => (
                        <Star
                          key={i}
                          className={`w-4 h-4 ${
                            i < review.rating
                              ? "text-[#D4AF37] fill-[#D4AF37]"
                              : "text-[#94A3B8]"
                          }`}
                        />
                      ))}
                    </div>
                  </div>
                  <span className="text-[#94A3B8] text-xs">{review.date}</span>
                </div>
                <p className="text-[#94A3B8] leading-relaxed">{review.comment}</p>
              </GlassCard>
            </motion.div>
          ))}
        </div>
      </motion.div>
    </div>
  );
}
