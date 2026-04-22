import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { ArrowLeft, ArrowUpRight, ArrowDownLeft, CreditCard } from "lucide-react";
import { GlassCard } from "../components/GlassCard";
import { DriverButton } from "../components/DriverButton";
import { apiClient } from "../lib/api";

export function WalletScreen() {
  const navigate = useNavigate();
  const [balance, setBalance] = useState(0);
  const [transactions, setTransactions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchWalletData();
  }, []);

  const fetchWalletData = async () => {
    try {
      const balanceData = await apiClient.get("/wallet/balance");
      const transData = await apiClient.get("/wallet/transactions");
      setBalance(balanceData.balance);
      setTransactions(transData.transactions);
    } catch (err) {
      console.error("Failed to fetch wallet data", err);
    } finally {
      setLoading(false);
    }
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
        <h2 className="text-2xl font-bold text-white">Wallet</h2>
      </div>

      {/* Balance Card */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="mb-8"
      >
        <GlassCard className="bg-gradient-to-br from-[#D4AF37]/30 to-[#F4D03F]/30 border-[#D4AF37]/50">
          <div className="mb-6">
            <p className="text-[#94A3B8] text-sm mb-2">Available Balance</p>
            <h1 className="text-5xl font-bold text-white mb-1">₹{balance.toLocaleString()}</h1>
            <p className="text-[#D4AF37] text-sm">Ready to withdraw</p>
          </div>
          
          <div className="grid grid-cols-2 gap-3">
            <DriverButton variant="primary" className="text-sm">
              Withdraw
            </DriverButton>
            <button className="bg-white/10 hover:bg-white/20 text-white font-semibold rounded-2xl px-6 py-4 transition-colors flex items-center justify-center gap-2">
              <CreditCard className="w-5 h-5" />
              Add Bank
            </button>
          </div>
        </GlassCard>
      </motion.div>

      {/* Quick Stats */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.1 }}
        className="grid grid-cols-3 gap-3 mb-8"
      >
        <div className="bg-[#1E3A5F]/40 backdrop-blur-xl border border-white/10 rounded-2xl p-4 text-center">
          <p className="text-[#94A3B8] text-xs mb-1">Today</p>
          <p className="text-white font-bold text-lg">₹1,250</p>
        </div>
        <div className="bg-[#1E3A5F]/40 backdrop-blur-xl border border-white/10 rounded-2xl p-4 text-center">
          <p className="text-[#94A3B8] text-xs mb-1">This Week</p>
          <p className="text-white font-bold text-lg">₹9,080</p>
        </div>
        <div className="bg-[#1E3A5F]/40 backdrop-blur-xl border border-white/10 rounded-2xl p-4 text-center">
          <p className="text-[#94A3B8] text-xs mb-1">This Month</p>
          <p className="text-white font-bold text-lg">₹42.5K</p>
        </div>
      </motion.div>

      {/* Transactions */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.2 }}
      >
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-white text-xl font-bold">Recent Transactions</h3>
          <button className="text-[#D4AF37] text-sm font-semibold">View All</button>
        </div>

        <div className="space-y-3">
          {transactions.map((tx, index) => (
            <motion.div
              key={tx.id}
              initial={{ x: -20, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: 0.3 + index * 0.05 }}
            >
              <GlassCard className="p-4">
                <div className="flex items-center gap-4">
                  <div className={`w-12 h-12 rounded-2xl flex items-center justify-center ${
                    tx.type === "credit" ? "bg-[#22C55E]" : "bg-[#EF4444]"
                  }`}>
                    {tx.type === "credit" ? (
                      <ArrowDownLeft className="w-6 h-6 text-white" />
                    ) : (
                      <ArrowUpRight className="w-6 h-6 text-white" />
                    )}
                  </div>
                  <div className="flex-1">
                    <h4 className="text-white font-semibold">{tx.desc}</h4>
                    <p className="text-[#94A3B8] text-sm">{tx.date}</p>
                  </div>
                  <div className="text-right">
                    <p className={`font-bold text-lg ${
                      tx.type === "credit" ? "text-[#22C55E]" : "text-[#EF4444]"
                    }`}>
                      {tx.type === "credit" ? "+" : "-"}₹{tx.amount}
                    </p>
                  </div>
                </div>
              </GlassCard>
            </motion.div>
          ))}
        </div>
      </motion.div>
    </div>
  );
}
