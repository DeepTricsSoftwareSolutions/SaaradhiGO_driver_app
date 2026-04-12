# Design System Strategy: High-Performance Driver Experience

## 1. Overview & Creative North Star
**Creative North Star: "The Obsidian Command Center"**

This design system moves away from the "utility-only" look of standard ride-sharing apps. Instead, it adopts a high-end, editorial aesthetic tailored for professional drivers. The visual identity is built on a foundation of **Tonal Depth** and **Intentional Asymmetry**. 

By utilizing a deep navy monochromatic base punctuated by a "Gold Standard" accent, we communicate authority, safety, and high performance. We break the rigid grid by overlapping map elements with glassmorphic floating panels, creating a sense of a physical, multi-layered cockpit rather than a flat digital screen.

---

## 2. Colors & Surface Architecture
Our palette is a sophisticated interplay of deep midnight tones and metallic highlights. We do not use "gray"; we use "slate" and "navy" to ensure the interface feels expensive and custom-built.

### The "No-Line" Rule
**Strict Directive:** 1px solid borders are prohibited for sectioning. 
Visual separation must be achieved through:
1.  **Background Shifts:** Placing a `surface-container-low` component against a `surface` background.
2.  **Tonal Transitions:** Using subtle gradients between `primary` and `primary-container`.
3.  **Negative Space:** Utilizing the **8pt spacing scale** to create cognitive boundaries.

### Surface Hierarchy (The Layering Principle)
Treat the UI as a physical stack. Each layer "rises" toward the user by shifting color, not by adding lines.
- **Base Level:** `surface` (#061425) - The bottom-most map or background layer.
- **Section Level:** `surface-container-low` (#0F1C2E) - For large grouped areas.
- **Interactive Level:** `surface-container-high` (#1E2A3D) - For primary driver cards and action sheets.
- **Floating Level:** `surface-container-highest` (#293548) - For urgent alerts or overlays.

### The "Glass & Gold" Signature
Main interactive cards (e.g., "New Trip Request") must use **Glassmorphism**. Apply a `surface-variant` color at 60% opacity with a **20px backdrop blur**. This allows the map's glow to bleed through, making the UI feel integrated into the environment. Use the `primary` (Gold) sparingly—only for high-value actions and status confirmations.

---

## 3. Typography
We use a dual-font system to balance "High-Performance" with "Legibility."

| Level | Token | Font | Size | Weight | Intent |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-sm` | Manrope | 2.25rem | Bold | High-impact earnings/stats |
| **Headline**| `headline-sm`| Manrope | 1.5rem | Semi-Bold | Screen titles/Main headers |
| **Title** | `title-md` | Inter | 1.125rem | Medium | Card titles/Navigation |
| **Body** | `body-lg` | Inter | 1rem | Regular | Essential trip details |
| **Label** | `label-md` | Inter | 0.75rem | Bold | Metadata/Upper-case tags |

**Editorial Note:** Use `display-sm` for the driver’s daily earnings. The contrast between the serif-like modernism of Manrope and the functional clarity of Inter creates a "Premium Tool" feel.

---

## 4. Elevation & Depth
In this system, elevation is an optical illusion created by light and transparency, not "drop shadows."

*   **Ambient Shadows:** For floating action buttons (FABs), use a shadow with a `48px` blur, `0%` spread, and `8%` opacity. The shadow color must be `on-surface` (#D6E3FC) to simulate light reflecting off the dark navy surfaces.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility, use the `outline-variant` (#4D4635) at **15% opacity**. It should be felt, not seen.
*   **Tactile Feedback:** Use `xl` (1.5rem) roundedness for large bottom sheets to soften the professional aesthetic, making it feel approachable and "safe."

---

## 5. Components

### High-Performance Buttons
*   **Primary (The Gold Standard):** Uses a gradient from `primary` (#F2CA50) to `primary-container` (#D4AF37). No border. Label uses `on-primary` (#3C2F00).
*   **Secondary:** `surface-container-highest` background with a `Ghost Border`.
*   **Interaction:** On press, the button should scale down to 97% to simulate a physical "click."

### Cards & Lists (The Divider-Free Approach)
*   **Trip List:** Use `surface-container-low` for the card. Separate individual trip items using **Spacing 4 (1rem)** vertical gaps. 
*   **Visual Anchor:** Use a 4px vertical "accent stripe" of `primary` (Gold) on the left edge of an active trip card to denote focus, rather than highlighting the whole card.

### Map Overlays
*   Overlays must use the `surface-container-highest` with a **60% opacity** and backdrop blur. 
*   Corner radius: `lg` (1rem).
*   Padding: Always use **Spacing 5 (1.25rem)** internal padding for "fat-finger" touch targets.

### Status Badges
*   **Active/Online:** `success` (#22C55E) text on a `success-container` (low opacity) background. 
*   **Warning/Busy:** `primary` (Gold) text on a `primary-container` background.

---

## 6. Do's and Don'ts

### Do
*   **DO** use asymmetric layouts for dashboard stats (e.g., large earnings on the left, smaller trip count stacked on the right).
*   **DO** use `surface-bright` (#2D3A4D) for hover/pressed states on dark containers.
*   **DO** ensure all touch targets (buttons/toggles) are at least 48dp high.

### Don't
*   **DON'T** use 100% black (#000000). It kills the depth of the Navy palette.
*   **DON'T** use standard Material Design dividers. Use whitespace or a `surface-container` shift.
*   **DON'T** use high-contrast white text on Gold buttons; use the specified `on-primary` deep brown for better legibility and a premium feel.
*   **DON'T** stack more than three levels of surface containers. It leads to visual "mud."

---

## 7. Platform Implementation (Flutter-Friendly)
When implementing in Flutter, leverage the `ThemeData` extensions for `ColorScheme`. Use `BackdropFilter` for all glassmorphic elements and `Container` decorations with `BoxShadow` using the "Ambient" settings defined in Section 4. Ensure `BorderRadius.custom` matches the Roundedness Scale (`xl` for sheets, `md` for inputs).