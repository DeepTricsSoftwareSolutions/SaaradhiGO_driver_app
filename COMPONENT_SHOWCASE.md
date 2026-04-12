# Component Showcase - SaaradhiGO Driver App

## Complete Component Library Reference

---

## 1. DriverButton

### Description
Primary button component with multiple variants and sizes. Includes press animations and disabled states.

### Props
```typescript
interface DriverButtonProps {
  variant?: "primary" | "secondary" | "success" | "error" | "disabled";
  size?: "sm" | "md" | "lg";
  children: React.ReactNode;
  disabled?: boolean;
  onClick?: () => void;
  className?: string;
}
```

### Usage Examples
```tsx
// Primary button (Gold)
<DriverButton variant="primary" onClick={handleSubmit}>
  Continue
</DriverButton>

// Success button (Green)
<DriverButton variant="success" onClick={handleAccept}>
  Accept Ride
</DriverButton>

// Error button (Red)
<DriverButton variant="error" onClick={handleReject}>
  Reject
</DriverButton>

// Secondary button (Navy)
<DriverButton variant="secondary">
  Cancel
</DriverButton>

// Disabled state
<DriverButton disabled>
  Please Wait
</DriverButton>

// Small size
<DriverButton size="sm">
  Small Button
</DriverButton>
```

### Visual Variants
- **Primary:** Gold background (#D4AF37), dark text, shadow
- **Secondary:** Navy background, white text, gold border
- **Success:** Green background (#22C55E), white text
- **Error:** Red background (#EF4444), white text
- **Disabled:** Muted colors, no interaction

### Flutter Equivalent
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFD4AF37),
    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  onPressed: () {},
  child: Text('Continue'),
)
```

---

## 2. GlassCard

### Description
Glassmorphism card with backdrop blur, subtle borders, and shadow. Perfect for overlays on maps or gradient backgrounds.

### Props
```typescript
interface GlassCardProps {
  children: ReactNode;
  className?: string;
}
```

### Usage Examples
```tsx
// Basic card
<GlassCard>
  <h3>Card Title</h3>
  <p>Card content goes here</p>
</GlassCard>

// With custom styling
<GlassCard className="mb-6 p-8">
  <div className="text-center">
    <h2>Custom Content</h2>
  </div>
</GlassCard>

// Nested in map overlay
<div className="absolute top-6 left-6">
  <GlassCard>
    <p>Today's Earnings: ₹1,250</p>
  </GlassCard>
</div>
```

### Visual Style
- Background: #1E3A5F with 40% opacity
- Backdrop blur: 24px
- Border: White with 10% opacity
- Border radius: 24px
- Shadow: Extra large, subtle
- Fade-in animation on mount

### Flutter Equivalent
```dart
Container(
  padding: EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: Color(0xFF1E3A5F).withOpacity(0.4),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: Colors.white.withOpacity(0.1),
      width: 1,
    ),
  ),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
    child: YourWidget(),
  ),
)
```

---

## 3. BottomSheet

### Description
Slide-up modal sheet with backdrop overlay. Supports gestures and animations.

### Props
```typescript
interface BottomSheetProps {
  isOpen: boolean;
  onClose: () => void;
  children: ReactNode;
  showCloseButton?: boolean;
}
```

### Usage Examples
```tsx
const [isOpen, setIsOpen] = useState(false);

// Basic bottom sheet
<BottomSheet 
  isOpen={isOpen} 
  onClose={() => setIsOpen(false)}
>
  <h2>Sheet Title</h2>
  <p>Sheet content</p>
</BottomSheet>

// With close button
<BottomSheet 
  isOpen={showMenu} 
  onClose={() => setShowMenu(false)}
  showCloseButton={true}
>
  <MenuContent />
</BottomSheet>

// Trigger button
<button onClick={() => setIsOpen(true)}>
  Open Sheet
</button>
```

### Features
- Backdrop blur overlay
- Spring animation (damping: 30, stiffness: 300)
- Drag handle indicator
- Max height: 85vh
- Scrollable content
- Click outside to dismiss

### Flutter Equivalent
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Color(0xFF1E3A5F),
  isScrollControlled: true,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
  ),
  builder: (context) => Container(
    padding: EdgeInsets.all(24),
    child: YourContent(),
  ),
)
```

---

## 4. StatusBadge

### Description
Compact status indicator with animated dot and label.

### Props
```typescript
interface StatusBadgeProps {
  status: "online" | "offline" | "ontrip" | "verified" | "pending";
  className?: string;
}
```

### Usage Examples
```tsx
// Online status
<StatusBadge status="online" />

// On trip
<StatusBadge status="ontrip" />

// Verification status
<StatusBadge status="verified" />
<StatusBadge status="pending" />

// Offline
<StatusBadge status="offline" />
```

### Status Variants
| Status | Color | Label | Dot Animation |
|--------|-------|-------|---------------|
| online | Green (#22C55E) | Online | Pulse |
| offline | Gray (#94A3B8) | Offline | None |
| ontrip | Gold (#D4AF37) | On Trip | Pulse |
| verified | Green (#22C55E) | Verified | Pulse |
| pending | Orange (#F59E0B) | Pending | Pulse |

### Flutter Equivalent
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(
    color: Color(0xFF22C55E),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
      SizedBox(width: 8),
      Text('Online', style: TextStyle(color: Colors.white)),
    ],
  ),
)
```

---

## 5. MapView

### Description
Google Maps placeholder with animated markers and route lines.

### Props
```typescript
interface MapViewProps {
  className?: string;
  showRoute?: boolean;
  pickupLocation?: { lat: number; lng: number };
  dropLocation?: { lat: number; lng: number };
}
```

### Usage Examples
```tsx
// Basic map
<MapView className="w-full h-full" />

// Map with route
<MapView 
  showRoute={true}
  className="absolute inset-0"
/>

// Full screen background
<div className="min-h-screen relative">
  <MapView className="absolute inset-0" showRoute={true} />
  <div className="relative z-10">
    {/* Your overlay content */}
  </div>
</div>
```

### Features
- Grid pattern background (simulates map tiles)
- Road lines overlay
- Driver location (gold pulsing marker)
- Route line (when showRoute=true)
- Pickup marker (green)
- Animated path drawing
- Ready for Google Maps API integration

### Google Maps Integration (Production)
```tsx
// Replace MapView with:
import { GoogleMap, Marker, Polyline } from '@react-google-maps/api';

<GoogleMap
  center={{ lat: 12.9716, lng: 77.5946 }}
  zoom={15}
  mapContainerStyle={{ width: '100%', height: '100%' }}
  options={{
    styles: darkMapStyles, // Custom dark theme
    disableDefaultUI: true,
  }}
>
  <Marker 
    position={driverLocation}
    icon="/driver-marker.png"
  />
  {showRoute && (
    <Polyline 
      path={routeCoordinates}
      options={{
        strokeColor: '#D4AF37',
        strokeWeight: 4,
      }}
    />
  )}
</GoogleMap>
```

### Flutter Equivalent
```dart
GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(12.9716, 77.5946),
    zoom: 15,
  ),
  markers: {
    Marker(
      markerId: MarkerId('driver'),
      position: driverLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueYellow,
      ),
    ),
  },
  polylines: showRoute ? {
    Polyline(
      polylineId: PolylineId('route'),
      points: routePoints,
      color: Color(0xFFD4AF37),
      width: 4,
    ),
  } : {},
)
```

---

## Design Patterns & Best Practices

### 1. Screen Layout Pattern
```tsx
<div className="min-h-screen bg-gradient-to-br from-[#0F1C2E] via-[#1E3A5F] to-[#0F1C2E] p-6">
  {/* Header */}
  <div className="flex items-center gap-4 mt-8 mb-12">
    <BackButton />
    <h2>Screen Title</h2>
  </div>

  {/* Content */}
  <motion.div
    initial={{ y: 20, opacity: 0 }}
    animate={{ y: 0, opacity: 1 }}
  >
    <GlassCard>
      {/* Content */}
    </GlassCard>
  </motion.div>

  {/* Bottom Action */}
  <div className="fixed bottom-6 left-6 right-6">
    <DriverButton>Action</DriverButton>
  </div>
</div>
```

### 2. Form Input Pattern
```tsx
<div>
  <label className="text-white text-sm mb-2 block">
    Label Text
  </label>
  <input
    className="w-full bg-[#0F1C2E]/50 border border-white/10 rounded-2xl px-6 py-5 text-white focus:outline-none focus:border-[#D4AF37] transition-colors"
    placeholder="Placeholder"
  />
</div>
```

### 3. List Item Pattern
```tsx
<GlassCard className="cursor-pointer hover:border-[#D4AF37]/50 transition-colors">
  <div className="flex items-center gap-4">
    <div className="w-12 h-12 bg-[#D4AF37] rounded-2xl flex items-center justify-center">
      <Icon className="w-6 h-6 text-[#0F1C2E]" />
    </div>
    <div className="flex-1">
      <h3 className="text-white font-semibold">Title</h3>
      <p className="text-[#94A3B8] text-sm">Description</p>
    </div>
    <ChevronRight className="w-5 h-5 text-[#94A3B8]" />
  </div>
</GlassCard>
```

### 4. Stats Grid Pattern
```tsx
<div className="grid grid-cols-2 gap-4">
  <GlassCard>
    <p className="text-[#94A3B8] text-sm mb-2">Label</p>
    <h3 className="text-white text-2xl font-bold">Value</h3>
  </GlassCard>
  {/* More cards... */}
</div>
```

### 5. Loading State Pattern
```tsx
<motion.div
  animate={{ opacity: [0.5, 1, 0.5] }}
  transition={{ duration: 1.5, repeat: Infinity }}
  className="h-20 bg-[#1E3A5F]/40 rounded-2xl"
/>
```

---

## Animation Cookbook

### Fade In
```tsx
<motion.div
  initial={{ opacity: 0 }}
  animate={{ opacity: 1 }}
  transition={{ duration: 0.3 }}
>
  Content
</motion.div>
```

### Slide Up
```tsx
<motion.div
  initial={{ y: 20, opacity: 0 }}
  animate={{ y: 0, opacity: 1 }}
  transition={{ delay: 0.2 }}
>
  Content
</motion.div>
```

### Scale Pop
```tsx
<motion.div
  initial={{ scale: 0 }}
  animate={{ scale: 1 }}
  transition={{ type: "spring", duration: 0.6 }}
>
  Content
</motion.div>
```

### Pulse Animation
```tsx
<motion.div
  animate={{ scale: [1, 1.2, 1] }}
  transition={{ duration: 2, repeat: Infinity }}
>
  Pulsing Element
</motion.div>
```

### Stagger Children
```tsx
{items.map((item, i) => (
  <motion.div
    key={i}
    initial={{ x: -20, opacity: 0 }}
    animate={{ x: 0, opacity: 1 }}
    transition={{ delay: i * 0.1 }}
  >
    {item}
  </motion.div>
))}
```

---

## Color Usage Guide

### When to Use Each Color

**Gold (#D4AF37):**
- Primary action buttons
- Earnings/money indicators
- Active states
- Premium features
- Icons for positive actions

**Green (#22C55E):**
- Success states
- Accept buttons
- Online status
- Positive metrics
- Call-to-action (start, complete)

**Red (#EF4444):**
- Error states
- Reject buttons
- Offline status
- SOS/Emergency
- Destructive actions

**Navy (#0F1C2E, #1E3A5F):**
- Backgrounds
- Cards
- Secondary buttons
- Neutral containers

**White/Gray (#FFFFFF, #94A3B8):**
- Text (primary/secondary)
- Icons
- Borders
- Subtle dividers

---

## Accessibility Checklist

- [ ] All touch targets ≥ 44x44px
- [ ] Color contrast ratio ≥ 4.5:1
- [ ] Focus states visible
- [ ] Keyboard navigation
- [ ] Screen reader labels
- [ ] Error messages clear
- [ ] Loading states announced

---

## Performance Tips

1. **Lazy load screens:** Use React.lazy() for route components
2. **Memoize components:** Use React.memo for list items
3. **Optimize animations:** Use transform and opacity only
4. **Image optimization:** WebP format, responsive sizes
5. **Code splitting:** Split by route
6. **Debounce inputs:** 300ms delay on search/filter

---

## Common Patterns

### Error State
```tsx
{error && (
  <motion.p
    initial={{ opacity: 0, y: -10 }}
    animate={{ opacity: 1, y: 0 }}
    className="text-[#EF4444] text-sm mt-2"
  >
    {error}
  </motion.p>
)}
```

### Empty State
```tsx
<div className="text-center py-20">
  <Icon className="w-16 h-16 text-[#94A3B8] mx-auto mb-4" />
  <h3 className="text-white text-xl font-bold mb-2">No Items</h3>
  <p className="text-[#94A3B8]">Description text</p>
</div>
```

### Loading Skeleton
```tsx
<div className="space-y-4">
  {[1, 2, 3].map(i => (
    <div key={i} className="h-24 bg-[#1E3A5F]/40 rounded-2xl animate-pulse" />
  ))}
</div>
```

---

This component library is production-ready and optimized for mobile driver apps. All components follow the 8pt spacing system and are touch-optimized for real-world usage.
