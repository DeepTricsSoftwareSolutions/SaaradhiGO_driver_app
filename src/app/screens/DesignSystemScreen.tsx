import { motion } from "motion/react";
import { ArrowLeft } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { DriverButton } from "../components/DriverButton";
import { GlassCard } from "../components/GlassCard";
import { StatusBadge } from "../components/StatusBadge";

export function DesignSystemScreen() {
  const navigate = useNavigate();

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
        <div>
          <h1 className="text-3xl font-bold text-white">Design System</h1>
          <p className="text-[#94A3B8]">SaaradhiGO Driver App</p>
        </div>
      </div>

      {/* Color Palette */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="mb-12"
      >
        <h2 className="text-2xl font-bold text-white mb-6">Color Palette</h2>
        <GlassCard>
          <div className="space-y-4">
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 bg-[#0F1C2E] rounded-2xl border border-white/20" />
              <div>
                <p className="text-white font-semibold">Navy Primary</p>
                <p className="text-[#94A3B8] text-sm">#0F1C2E</p>
              </div>
            </div>
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 bg-[#1E3A5F] rounded-2xl border border-white/20" />
              <div>
                <p className="text-white font-semibold">Navy Secondary</p>
                <p className="text-[#94A3B8] text-sm">#1E3A5F</p>
              </div>
            </div>
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 bg-[#D4AF37] rounded-2xl" />
              <div>
                <p className="text-white font-semibold">Gold Accent</p>
                <p className="text-[#94A3B8] text-sm">#D4AF37</p>
              </div>
            </div>
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 bg-[#22C55E] rounded-2xl" />
              <div>
                <p className="text-white font-semibold">Success</p>
                <p className="text-[#94A3B8] text-sm">#22C55E</p>
              </div>
            </div>
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 bg-[#EF4444] rounded-2xl" />
              <div>
                <p className="text-white font-semibold">Error</p>
                <p className="text-[#94A3B8] text-sm">#EF4444</p>
              </div>
            </div>
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 bg-[#FFFFFF] rounded-2xl border border-white/20" />
              <div>
                <p className="text-white font-semibold">Text Primary</p>
                <p className="text-[#94A3B8] text-sm">#FFFFFF</p>
              </div>
            </div>
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 bg-[#94A3B8] rounded-2xl" />
              <div>
                <p className="text-white font-semibold">Text Secondary</p>
                <p className="text-[#94A3B8] text-sm">#94A3B8</p>
              </div>
            </div>
          </div>
        </GlassCard>
      </motion.div>

      {/* Typography */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.1 }}
        className="mb-12"
      >
        <h2 className="text-2xl font-bold text-white mb-6">Typography</h2>
        <GlassCard>
          <div className="space-y-6">
            <div>
              <p className="text-[#94A3B8] text-sm mb-2">H1 - 26-28px Bold</p>
              <h1 className="text-white">The quick brown fox</h1>
            </div>
            <div>
              <p className="text-[#94A3B8] text-sm mb-2">H2 - 20-22px</p>
              <h2 className="text-white">The quick brown fox</h2>
            </div>
            <div>
              <p className="text-[#94A3B8] text-sm mb-2">Body - 16px</p>
              <p className="text-white">The quick brown fox jumps over the lazy dog</p>
            </div>
            <div>
              <p className="text-[#94A3B8] text-sm mb-2">Caption - 13px</p>
              <p className="text-white text-sm">The quick brown fox jumps over the lazy dog</p>
            </div>
          </div>
        </GlassCard>
      </motion.div>

      {/* Buttons */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="mb-12"
      >
        <h2 className="text-2xl font-bold text-white mb-6">Buttons</h2>
        <GlassCard>
          <div className="space-y-4">
            <div>
              <p className="text-[#94A3B8] text-sm mb-3">Primary</p>
              <DriverButton variant="primary">Primary Button</DriverButton>
            </div>
            <div>
              <p className="text-[#94A3B8] text-sm mb-3">Secondary</p>
              <DriverButton variant="secondary">Secondary Button</DriverButton>
            </div>
            <div>
              <p className="text-[#94A3B8] text-sm mb-3">Success</p>
              <DriverButton variant="success">Success Button</DriverButton>
            </div>
            <div>
              <p className="text-[#94A3B8] text-sm mb-3">Error</p>
              <DriverButton variant="error">Error Button</DriverButton>
            </div>
            <div>
              <p className="text-[#94A3B8] text-sm mb-3">Disabled</p>
              <DriverButton disabled>Disabled Button</DriverButton>
            </div>
          </div>
        </GlassCard>
      </motion.div>

      {/* Status Badges */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.3 }}
        className="mb-12"
      >
        <h2 className="text-2xl font-bold text-white mb-6">Status Badges</h2>
        <GlassCard>
          <div className="space-y-4">
            <StatusBadge status="online" />
            <StatusBadge status="offline" />
            <StatusBadge status="ontrip" />
            <StatusBadge status="verified" />
            <StatusBadge status="pending" />
          </div>
        </GlassCard>
      </motion.div>

      {/* Cards */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.4 }}
        className="mb-12"
      >
        <h2 className="text-2xl font-bold text-white mb-6">Glass Card</h2>
        <GlassCard>
          <h3 className="text-white text-xl font-bold mb-2">Card Title</h3>
          <p className="text-[#94A3B8]">
            This is a glassmorphism card with backdrop blur and subtle borders.
            Perfect for mobile UI overlays.
          </p>
        </GlassCard>
      </motion.div>

      {/* Spacing System */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.5 }}
        className="mb-12"
      >
        <h2 className="text-2xl font-bold text-white mb-6">Spacing System (8pt)</h2>
        <GlassCard>
          <div className="space-y-3">
            <div className="flex items-center gap-4">
              <div className="w-2 h-8 bg-[#D4AF37] rounded" />
              <p className="text-white">8px (0.5rem)</p>
            </div>
            <div className="flex items-center gap-4">
              <div className="w-4 h-8 bg-[#D4AF37] rounded" />
              <p className="text-white">16px (1rem)</p>
            </div>
            <div className="flex items-center gap-4">
              <div className="w-6 h-8 bg-[#D4AF37] rounded" />
              <p className="text-white">24px (1.5rem)</p>
            </div>
            <div className="flex items-center gap-4">
              <div className="w-8 h-8 bg-[#D4AF37] rounded" />
              <p className="text-white">32px (2rem)</p>
            </div>
          </div>
        </GlassCard>
      </motion.div>

      {/* Flutter Widget Mapping */}
      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.6 }}
        className="mb-12"
      >
        <h2 className="text-2xl font-bold text-white mb-6">Flutter Widget Mapping</h2>
        <GlassCard>
          <div className="space-y-4 text-sm">
            <div className="border-b border-white/10 pb-3">
              <p className="text-[#D4AF37] font-semibold mb-1">DriverButton</p>
              <p className="text-[#94A3B8]">→ ElevatedButton / CustomButton</p>
            </div>
            <div className="border-b border-white/10 pb-3">
              <p className="text-[#D4AF37] font-semibold mb-1">GlassCard</p>
              <p className="text-[#94A3B8]">→ Container with BackdropFilter</p>
            </div>
            <div className="border-b border-white/10 pb-3">
              <p className="text-[#D4AF37] font-semibold mb-1">BottomSheet</p>
              <p className="text-[#94A3B8]">→ showModalBottomSheet</p>
            </div>
            <div className="border-b border-white/10 pb-3">
              <p className="text-[#D4AF37] font-semibold mb-1">StatusBadge</p>
              <p className="text-[#94A3B8]">→ Chip / Custom Badge Widget</p>
            </div>
            <div className="border-b border-white/10 pb-3">
              <p className="text-[#D4AF37] font-semibold mb-1">MapView</p>
              <p className="text-[#94A3B8]">→ GoogleMap (google_maps_flutter)</p>
            </div>
            <div>
              <p className="text-[#D4AF37] font-semibold mb-1">Animations</p>
              <p className="text-[#94A3B8]">→ AnimatedContainer / Hero / PageRouteBuilder</p>
            </div>
          </div>
        </GlassCard>
      </motion.div>
    </div>
  );
}
