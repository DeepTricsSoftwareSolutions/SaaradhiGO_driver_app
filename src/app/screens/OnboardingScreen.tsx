import { useState, useRef } from "react";
import { useNavigate } from "react-router";
import { motion } from "motion/react";
import { Camera, Check, FileText, CreditCard, Car, Loader2 } from "lucide-react";
import { DriverButton } from "../components/DriverButton";
import { GlassCard } from "../components/GlassCard";
import { apiClient } from "../lib/api";

export function OnboardingScreen() {
  const navigate = useNavigate();
  const [documents, setDocuments] = useState({
    aadhaar: false,
    license: false,
    rc: false,
  });
  const [loading, setLoading] = useState<Record<string, boolean>>({});

  const fileInputs = {
    aadhaar: useRef<HTMLInputElement>(null),
    license: useRef<HTMLInputElement>(null),
    rc: useRef<HTMLInputElement>(null),
  };

  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>, docType: keyof typeof documents) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setLoading(prev => ({ ...prev, [docType]: true }));
    try {
      const formData = new FormData();
      // Map frontend keys to backend field names
      const backendField = docType === 'license' ? 'license' : docType === 'rc' ? 'rc' : 'aadhaar';
      formData.append(backendField, file);
      
      await apiClient.post("/driver/documents", formData);
      setDocuments(prev => ({ ...prev, [docType]: true }));
    } catch (err) {
      console.error("Upload failed", err);
      alert("Failed to upload document. Please try again.");
    } finally {
      setLoading(prev => ({ ...prev, [docType]: false }));
    }
  };

  const allDocsUploaded = Object.values(documents).every((doc) => doc);

  const DocumentCard = ({ 
    icon: Icon, 
    title, 
    description, 
    docKey, 
    uploaded 
  }: { 
    icon: any; 
    title: string; 
    description: string; 
    docKey: keyof typeof documents; 
    uploaded: boolean 
  }) => (
    <motion.div
      whileTap={{ scale: 0.98 }}
      onClick={() => !uploaded && !loading[docKey] && fileInputs[docKey].current?.click()}
      className={`bg-[#0F1C2E]/50 border ${
        uploaded ? "border-[#22C55E]" : "border-white/10"
      } rounded-2xl p-6 cursor-pointer hover:border-[#D4AF37]/50 transition-all`}
    >
      <input
        type="file"
        ref={fileInputs[docKey]}
        onChange={(e) => handleFileChange(e, docKey)}
        className="hidden"
        accept="image/*,application/pdf"
      />
      <div className="flex items-start gap-4">
        <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
          uploaded ? "bg-[#22C55E]" : "bg-[#D4AF37]"
        }`}>
          {loading[docKey] ? (
            <Loader2 className="w-6 h-6 text-[#0F1C2E] animate-spin" />
          ) : uploaded ? (
            <Check className="w-6 h-6 text-white" />
          ) : (
            <Icon className="w-6 h-6 text-[#0F1C2E]" />
          )}
        </div>
        <div className="flex-1">
          <h3 className="text-white font-semibold mb-1">{title}</h3>
          <p className="text-[#94A3B8] text-sm">{description}</p>
        </div>
        {!uploaded && !loading[docKey] && (
          <Camera className="w-5 h-5 text-[#D4AF37]" />
        )}
      </div>
    </motion.div>
  );

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] p-6">
      {/* Header */}
      <motion.div
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="mt-8 mb-12"
      >
        <h1 className="text-3xl font-bold text-white mb-2">
          Complete Your Profile
        </h1>
        <p className="text-[#94A3B8] text-lg">
          Upload required documents to get started
        </p>
      </motion.div>

      {/* Progress */}
      <GlassCard className="mb-8">
        <div className="flex items-center justify-between mb-3">
          <span className="text-white font-semibold">Progress</span>
          <span className="text-[#D4AF37] font-semibold">
            {Object.values(documents).filter(Boolean).length}/3
          </span>
        </div>
        <div className="h-3 bg-[#0F1C2E]/50 rounded-full overflow-hidden">
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${(Object.values(documents).filter(Boolean).length / 3) * 100}%` }}
            transition={{ duration: 0.5 }}
            className="h-full bg-gradient-to-r from-[#D4AF37] to-[#F4D03F]"
          />
        </div>
      </GlassCard>

      {/* Documents */}
      <div className="space-y-4 mb-8">
        <DocumentCard
          icon={FileText}
          title="Aadhaar Card"
          description="Upload front and back of your Aadhaar"
          docKey="aadhaar"
          uploaded={documents.aadhaar}
        />
        <DocumentCard
          icon={CreditCard}
          title="Driving License"
          description="Valid driving license required"
          docKey="license"
          uploaded={documents.license}
        />
        <DocumentCard
          icon={Car}
          title="Vehicle RC"
          description="Vehicle registration certificate"
          docKey="rc"
          uploaded={documents.rc}
        />
      </div>

      {/* Submit Button */}
      <DriverButton
        onClick={() => navigate("/verification")}
        disabled={!allDocsUploaded}
        className="w-full"
      >
        Submit for Verification
      </DriverButton>
    </div>
  );
}
