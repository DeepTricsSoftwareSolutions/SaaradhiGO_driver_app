interface StatusBadgeProps {
  status: "online" | "offline" | "ontrip" | "verified" | "pending";
  className?: string;
}

export function StatusBadge({ status, className = "" }: StatusBadgeProps) {
  const variants = {
    online: "bg-[#22C55E] text-white",
    offline: "bg-[#94A3B8] text-white",
    ontrip: "bg-[#D4AF37] text-[#0F1C2E]",
    verified: "bg-[#22C55E] text-white",
    pending: "bg-[#F59E0B] text-white",
  };
  
  const labels = {
    online: "Online",
    offline: "Offline",
    ontrip: "On Trip",
    verified: "Verified",
    pending: "Pending",
  };

  return (
    <div className={`inline-flex items-center gap-2 px-4 py-2 rounded-full font-semibold text-sm ${variants[status]} ${className}`}>
      <div className="w-2 h-2 rounded-full bg-current animate-pulse" />
      {labels[status]}
    </div>
  );
}
