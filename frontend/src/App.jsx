import { GamePage } from "./pages/GamePage/GamePage";
import { LandingPage } from "./pages/LandingPage/LandingPage";
import { GameModePage } from "./pages/GameModePage/GameModePage";
import { WaitingRoomPage } from "./pages/WaitingRoomPage/WaitingRoomPage";

import "./App.css";

import { Routes, Route } from "react-router-dom";

function App() {
  return (
    <div className="container">
      <Routes>
        <Route path="" element={<LandingPage />} />
        <Route path="mode" element={<GameModePage />} />
        <Route path="wroom" element={<WaitingRoomPage />} />
        <Route path="game" element={<GamePage />} />
      </Routes>
    </div>
  );
}

export default App;
