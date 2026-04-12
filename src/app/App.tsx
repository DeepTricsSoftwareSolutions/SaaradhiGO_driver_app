import { RouterProvider } from "react-router";
import { router } from "./routes";

export default function App() {
  return (
    <div className="max-w-[390px] mx-auto min-h-screen bg-[#0F1C2E]">
      <RouterProvider router={router} />
    </div>
  );
}
