import { GamePage } from "./pages/GamePage/GamePage";
import { LandingPage } from "./pages/LandingPage/LandingPage";
import { GameModePage } from "./pages/GameModePage/GameModePage";
import { WaitingRoomPage } from "./pages/WaitingRoomPage/WaitingRoomPage";
import { AuthPage } from "./pages/AuthPage/AuthPage";
import { RequireAuth } from "./components/AuthContext/RequireAuth";

import "./App.css";

import { Routes, Route } from "react-router-dom";

function App() {
  return (
    <div className="container">
      <Routes>
        <Route path="" element={<LandingPage />} />
        <Route path="auth" element={<AuthPage />} />
        {/*  <Route path="/" element={<RequireAuth />}> */}
        <Route path="mode" element={<GameModePage />} />
        <Route path="wroom" element={<WaitingRoomPage />} />
        <Route path="game" element={<GamePage />} />
        {/*  </Route> */}
      </Routes>
    </div>
  );
}

export default App;
