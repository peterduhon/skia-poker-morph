import { PokerTable } from "../../components/PokerTable/PokerTable";
import { AIGame } from "../../components/AIGame/AIGame";

export const GamePage = () => {
  return (
    <PokerTable>
      <AIGame />
    </PokerTable>
  );
};
