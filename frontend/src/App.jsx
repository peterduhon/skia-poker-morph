import { Navigate, Routes, Route } from "react-router-dom";

import { HomePage } from "./pages/HomePage/HomePage";
import { GamePage } from "./pages/GamePage/GamePage";

function App() {
  return (
    <Routes>
      <Route index element={<HomePage />} />
      <Route path="game" element={<GamePage />} />
      <Route path="/*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default App;
