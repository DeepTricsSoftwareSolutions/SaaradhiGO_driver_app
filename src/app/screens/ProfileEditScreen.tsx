import { useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { ArrowLeft, Upload, Check, AlertCircle } from "lucide-react";
import { GlassCard } from "../components/GlassCard";
import { DriverButton } from "../components/DriverButton";
import { apiClient } from "../lib/api";

export function ProfileEditScreen() {
  const navigate = useNavigate();
  const fileInputs = useRef<Record<string, HTMLInputElement | null>>({});

  const [formData, setFormData] = useState({
    fullName: "",
    aadharNumber: "",
    panNumber: "",
    vehicleNumber: "",
    rcNumber: "",
    vehicleBrand: "",
    vehicleModel: "",
    vehicleYear: new Date().getFullYear().toString(),
  });

  const [uploading, setUploading] = useState<Record<string, boolean>>({});
  const [photos, setPhotos] = useState<Record<string, File | null>>({
    profile: null,
    front: null,
    back: null,
    interior: null,
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const handleInputChange = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
    setError("");
  };

  const handleFileSelect = (type: string, file: File | null) => {
    if (!file) return;
    
    setUploading((prev) => ({ ...prev, [type]: true }));
    
    // Simulate file upload
    setTimeout(() => {
      setPhotos((prev) => ({ ...prev, [type]: file }));
      setUploading((prev) => ({ ...prev, [type]: false }));
    }, 500);
  };

  const validateForm = (): boolean => {
    setError("");

    if (!formData.fullName.trim()) {
      setError("Full name is required");
      return false;
    }
    if (!formData.aadharNumber.trim()) {
      setError("Aadhar number is required");
      return false;
    }
    if (!formData.panNumber.trim()) {
      setError("PAN number is required");
      return false;
    }
    if (!formData.vehicleNumber.trim()) {
      setError("Vehicle number is required");
      return false;
    }
    if (!formData.rcNumber.trim()) {
      setError("RC number is required");
      return false;
    }
    if (!formData.vehicleBrand.trim() || !formData.vehicleModel.trim()) {
      setError("Vehicle brand and model are required");
      return false;
    }
    if (!formData.vehicleYear.trim()) {
      setError("Vehicle year is required");
      return false;
    }

    return true;
  };

  const handleSubmit = async () => {
    if (!validateForm()) return;

    setIsLoading(true);
    try {
      await apiClient.patch("/driver/profile", {
        fullName: formData.fullName,
        aadharNumber: formData.aadharNumber,
        panNumber: formData.panNumber,
        vehicleNumber: formData.vehicleNumber,
        rcNumber: formData.rcNumber,
        vehicleBrand: formData.vehicleBrand,
        vehicleModel: formData.vehicleModel,
        vehicleYear: Number(formData.vehicleYear),
      });

      if (photos.profile || photos.front || photos.back || photos.interior) {
        const uploadForm = new FormData();
        if (photos.profile) uploadForm.append("profilePhoto", photos.profile);
        if (photos.front) uploadForm.append("vehiclePhotoFront", photos.front);
        if (photos.back) uploadForm.append("vehiclePhotoBack", photos.back);
        if (photos.interior) uploadForm.append("vehiclePhotoInterior", photos.interior);
        uploadForm.append("submit", "false");
        await apiClient.post("/driver/documents", uploadForm);
      }

      setSuccess("Profile updated successfully!");
      setTimeout(() => {
        navigate("/profile");
      }, 1500);
    } catch (err: any) {
      setError(err.message || "Failed to save profile");
    } finally {
      setIsLoading(false);
    }
  };

  const renderPhotoUpload = (type: string, label: string) => (
    <motion.div
      initial={{ y: 20, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      className="mb-6"
    >
      <label className="text-[#94A3B8] text-sm mb-2 block">{label}</label>
      <input
        ref={(el) => (fileInputs.current[type] = el)}
        type="file"
        accept="image/*"
        onChange={(e) => handleFileSelect(type, e.target.files?.[0] || null)}
        className="hidden"
      />
      <button
        onClick={() => fileInputs.current[type]?.click()}
        disabled={uploading[type]}
        className={`w-full relative overflow-hidden border-2 border-dashed rounded-2xl p-8 transition-all ${
          photos[type]
            ? "border-[#22C55E] bg-[#22C55E]/5"
            : "border-white/20 bg-white/5 hover:border-[#D4AF37]/50"
        }`}
      >
        {photos[type] && (
          <div className="absolute inset-0">
            <img
              src={URL.createObjectURL(photos[type])}
              alt={label}
              className="w-full h-full object-cover"
            />
          </div>
        )}
        <div className={`relative flex flex-col items-center gap-3 ${photos[type] ? "hidden" : ""}`}>
          {uploading[type] ? (
            <>
              <div className="w-12 h-12 border-4 border-[#D4AF37]/30 border-t-[#D4AF37] rounded-full animate-spin" />
              <p className="text-[#94A3B8] text-sm">Uploading...</p>
            </>
          ) : photos[type] ? (
            <>
              <Check className="w-8 h-8 text-[#22C55E]" />
              <p className="text-[#22C55E] text-sm font-semibold">Attached</p>
            </>
          ) : (
            <>
              <Upload className="w-8 h-8 text-[#D4AF37]" />
              <p className="text-white font-semibold">Click to upload</p>
              <p className="text-[#94A3B8] text-xs">or drag and drop</p>
            </>
          )}
        </div>
      </button>
    </motion.div>
  );

  const renderTextField = (label: string, field: string, placeholder: string, isUppercase = false) => (
    <motion.div initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }} className="mb-6">
      <label className="text-[#94A3B8] text-sm mb-2 block">{label}</label>
      <input
        type="text"
        placeholder={placeholder}
        value={formData[field as keyof typeof formData]}
        onChange={(e) =>
          handleInputChange(
            field,
            isUppercase ? e.target.value.toUpperCase() : e.target.value
          )
        }
        className="w-full bg-[#0F1C2E]/50 border border-white/10 rounded-2xl px-4 py-3 text-white placeholder:text-[#94A3B8]/50 focus:outline-none focus:border-[#D4AF37] transition-colors"
      />
    </motion.div>
  );

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] p-6">
      {/* Header */}
      <div className="flex items-center gap-4 mt-8 mb-12">
        <button
          onClick={() => navigate("/profile")}
          className="w-12 h-12 bg-white/10 rounded-2xl flex items-center justify-center hover:bg-white/20 transition-colors"
        >
          <ArrowLeft className="w-6 h-6 text-white" />
        </button>
        <h2 className="text-2xl font-bold text-white">Edit Profile</h2>
      </div>

      <div className="max-w-2xl mx-auto">
        {/* Error Alert */}
        {error && (
          <motion.div
            initial={{ y: -10, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            className="mb-6 p-4 bg-[#EF4444]/20 border border-[#EF4444]/30 rounded-2xl flex items-center gap-3"
          >
            <AlertCircle className="w-5 h-5 text-[#EF4444]" />
            <p className="text-[#EF4444] text-sm">{error}</p>
          </motion.div>
        )}

        {/* Success Alert */}
        {success && (
          <motion.div
            initial={{ y: -10, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            className="mb-6 p-4 bg-[#22C55E]/20 border border-[#22C55E]/30 rounded-2xl flex items-center gap-3"
          >
            <Check className="w-5 h-5 text-[#22C55E]" />
            <p className="text-[#22C55E] text-sm">{success}</p>
          </motion.div>
        )}

        {/* Personal Details */}
        <GlassCard className="mb-8">
          <h3 className="text-white font-semibold text-lg mb-6">Personal Details</h3>
          {renderTextField("Full Name", "fullName", "John Doe")}
          {renderTextField("Aadhar Number", "aadharNumber", "1234 5678 9012")}
          {renderTextField("PAN Number", "panNumber", "ABCDE1234F", true)}
        </GlassCard>

        {/* Profile Photo */}
        <GlassCard className="mb-8">
          <h3 className="text-white font-semibold text-lg mb-6">Profile Photo</h3>
          {renderPhotoUpload("profile", "Profile Photo")}
        </GlassCard>

        {/* Vehicle Details */}
        <GlassCard className="mb-8">
          <h3 className="text-white font-semibold text-lg mb-6">Vehicle Details</h3>
          {renderTextField("Vehicle Number", "vehicleNumber", "KA 01 AB 1234", true)}
          {renderTextField("RC Number", "rcNumber", "DL 01 AB 0001234")}
          {renderTextField("Vehicle Brand", "vehicleBrand", "Maruti Suzuki")}
          {renderTextField("Vehicle Model", "vehicleModel", "Swift")}
          {renderTextField("Vehicle Year", "vehicleYear", new Date().getFullYear().toString())}
        </GlassCard>

        {/* Vehicle Photos */}
        <GlassCard className="mb-8">
          <h3 className="text-white font-semibold text-lg mb-6">Vehicle Photos</h3>
          {renderPhotoUpload("front", "Front View")}
          {renderPhotoUpload("back", "Back View")}
          {renderPhotoUpload("interior", "Interior View")}
        </GlassCard>

        {/* Submit Button */}
        <motion.div initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }}>
          <DriverButton
            onClick={handleSubmit}
            disabled={isLoading}
            className="w-full"
          >
            {isLoading ? (
              <div className="flex items-center justify-center gap-2">
                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                Saving...
              </div>
            ) : (
              "Save Profile"
            )}
          </DriverButton>
        </motion.div>
      </div>
    </div>
  );
}
