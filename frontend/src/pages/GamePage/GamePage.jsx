import "./game.scss";
import { Player } from "../../components/Player/Player";
import { CommunityCards } from "../../components/CommunityCards/CommunityCard";

/* //frontend listen to players, currentPlayer, phase, communityCards */
let phase = "pre-flop";
const currentPlayer = "Peter";
const users = [
  { name: "Peter", cards: ["op", "jk"] },
  { name: "Don", cards: ["gh", "nm"] },
  { name: "Anna", cards: ["er", "gf"] },
  { name: "Sasha", cards: ["kl", "hj"] },
  { name: "Alex", cards: ["kl", "hj"] },
];

const communityCards = ["gh", "fg", "jk", "hj", "hj"];

export const GamePage = () => {
  return (
    <>
      <div className="game">
        <CommunityCards cards={communityCards} />
        <div className="game__user0">
          <Player
            name={users[0].name}
            cards={users[0].cards}
            role={users[0].role}
          />
        </div>
        <div className="game__user1">
          <Player
            name={users[1].name}
            cards={users[1].cards}
            role={users[1].role}
          />
        </div>
        <div className="game__user2">
          <Player
            name={users[2].name}
            cards={users[2].cards}
            role={users[2].role}
          />
        </div>
        <div className="game__user3">
          <Player
            name={users[3].name}
            cards={users[3].cards}
            role={users[3].role}
          />
        </div>
        <div className="game__user4">
          <Player
            name={users[4].name}
            cards={users[4].cards}
            role={users[4].role}
          />
        </div>
      </div>
      <div
        style={{
          position: "absolute",
          top: 100,
          left: 100,
          backgroundColor: "yellow",
          padding: 10,
        }}
      >
        Current player {currentPlayer}
      </div>
      <div
        style={{
          position: "absolute",
          top: 100,
          left: 600,
          maxWidth: 80,
          backgroundColor: "yellow",
          padding: 10,
        }}
      >
        {phase}
      </div>
      <div
        className="actions"
        style={{ position: "absolute", top: 100, left: 1000 }}
      >
        <button
          style={{ maxWidth: 50, backgroundColor: "yellow", padding: 10 }}
        >
          Folt
        </button>
        <button
          style={{ maxWidth: 50, backgroundColor: "yellow", padding: 10 }}
        >
          Call
        </button>
        <button
          style={{ maxWidth: 50, backgroundColor: "yellow", padding: 10 }}
        >
          Raise
        </button>
      </div>
    </>
  );
};
