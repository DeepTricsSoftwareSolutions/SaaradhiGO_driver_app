import { createBrowserRouter } from "react-router";
import { SplashScreen } from "./screens/SplashScreen";
import { LoginScreen } from "./screens/LoginScreen";
import { OTPScreen } from "./screens/OTPScreen";
import { OnboardingScreen } from "./screens/OnboardingScreen";
import { VerificationScreen } from "./screens/VerificationScreen";
import { DriverHomeScreen } from "./screens/DriverHomeScreen";
import { RideRequestScreen } from "./screens/RideRequestScreen";
import { PickupNavigationScreen } from "./screens/PickupNavigationScreen";
import { StartRideScreen } from "./screens/StartRideScreen";
import { LiveTripScreen } from "./screens/LiveTripScreen";
import { EndTripScreen } from "./screens/EndTripScreen";
import { EarningsScreen } from "./screens/EarningsScreen";
import { WalletScreen } from "./screens/WalletScreen";
import { RideHistoryScreen } from "./screens/RideHistoryScreen";
import { RatingsScreen } from "./screens/RatingsScreen";
import { NotificationsScreen } from "./screens/NotificationsScreen";
import { SafetyScreen } from "./screens/SafetyScreen";
import { SettingsScreen } from "./screens/SettingsScreen";
import { DesignSystemScreen } from "./screens/DesignSystemScreen";
import { NavigationGuideScreen } from "./screens/NavigationGuideScreen";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: NavigationGuideScreen,
  },
  {
    path: "/splash",
    Component: SplashScreen,
  },
  {
    path: "/login",
    Component: LoginScreen,
  },
  {
    path: "/otp",
    Component: OTPScreen,
  },
  {
    path: "/onboarding",
    Component: OnboardingScreen,
  },
  {
    path: "/verification",
    Component: VerificationScreen,
  },
  {
    path: "/home",
    Component: DriverHomeScreen,
  },
  {
    path: "/ride-request",
    Component: RideRequestScreen,
  },
  {
    path: "/pickup-navigation",
    Component: PickupNavigationScreen,
  },
  {
    path: "/start-ride",
    Component: StartRideScreen,
  },
  {
    path: "/live-trip",
    Component: LiveTripScreen,
  },
  {
    path: "/end-trip",
    Component: EndTripScreen,
  },
  {
    path: "/earnings",
    Component: EarningsScreen,
  },
  {
    path: "/wallet",
    Component: WalletScreen,
  },
  {
    path: "/history",
    Component: RideHistoryScreen,
  },
  {
    path: "/ratings",
    Component: RatingsScreen,
  },
  {
    path: "/notifications",
    Component: NotificationsScreen,
  },
  {
    path: "/safety",
    Component: SafetyScreen,
  },
  {
    path: "/settings",
    Component: SettingsScreen,
  },
  {
    path: "/design-system",
    Component: DesignSystemScreen,
  },
]);