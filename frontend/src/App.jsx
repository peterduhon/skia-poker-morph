import { GamePage } from "./pages/GamePage/GamePage";
import { PokerTable } from "./components/PokerTable/PokerTable";
import "./App.css";

function App() {
  return (
    <div className="container">
      <PokerTable>
        <GamePage />
      </PokerTable>
    </div>
  );
}

export default App;
