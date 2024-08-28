import "./game.scss";
import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import tables from "../../data/tables.json";
import { Player } from "../../components/Player/Player";
import cardsGeneral from "../../data/cards.json";
import { Timer } from "../../components/Timer/Timer";
import { CommunityCards } from "../../components/CommunityCards/CommunityCard";

const randomCard = (max) => {
  return Math.floor(Math.random() * max);
};
/* //smart contract read users */
const usersInit = [
  { name: "Peter", cards: [], chips: 0, active: true, role: "" },
  { name: "Don", cards: [], chips: 0, active: true, role: "" },
  { name: "Anna", cards: [], chips: 0, active: true, role: "" },
  { name: "Sasha", cards: [], chips: 0, active: true, role: "" },
  { name: "Alex", cards: [], chips: 0, active: true, role: "" },
];

export const GamePage = () => {
  const [users, setUsers] = useState(usersInit);
  const [timeLeft, setTimeLeft] = useState(20);
  const [roundGame, setRoundGame] = useState(0);
  const [activePlayer, setActivePlayer] = useState(usersInit[0]);
  const [communityCards, setCommunityCards] = useState([]);
  const [cards, setCards] = useState(cardsGeneral);

  useEffect(() => {
    if (roundGame === 1) {
      determinateDiler();
      setCards(cardsGeneral);
      setRoundGame(2);

      console.log("roundGame", roundGame);
    }
  }, [roundGame]);

  useEffect(() => {
    if (roundGame === 2) {
      dealCards();
      console.log("roundGame", roundGame);
    }
  }, [roundGame]);

  async function dealCards() {
    let max = 35;
    for (let user of users) {
      const n = randomCard(max);
      console.log("user", user);
      user.cards.push(cards[n]);
      cards.splice(n, 1);
      setUsers((prev) => [...prev]);
      max = max - 1;
    }
    for (let user of users) {
      const n = randomCard(max);
      console.log("user", user);
      user.cards.push(cards[n]);
      cards.splice(n, 1);
      setUsers((prev) => [...prev]);
      max = max - 1;
    }
  }

  async function determinateDiler() {
    let max = 35;
    let diler = 0;
    for (let user of users) {
      const n = randomCard(max);
      if (n > diler) {
        diler = n;
      }
      user.cards.push(cards[n]);
      cards.splice(n, 1);
      setUsers((prev) => [...prev]);
      max = max - 1;
    }
    users[diler].role = "diler";
  }

  const timer = setInterval(() => {
    setTimeLeft((prevTime) => {
      if (prevTime === 0) {
        clearInterval(timer);
        setRoundGame(1);
        console.log("Countdown complete!");
        return 0;
      } else {
        return prevTime - 1;
      }
    });
  }, 1000);

  return (
    <>
      {timeLeft > 0 && (
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            height: 20,
            marginBottom: 10,
          }}
        >
          <div
            style={{
              size: 20,
              padding: 5,
              border: "1px solid",
              backgroundColor: "green",
            }}
          >
            {timeLeft}
          </div>
          <button
            style={{ backgroundColor: "green", padding: 10 }}
            onClick={() => {
              setTimeLeft(-1);
            }}
          >
            Start game
          </button>
        </div>
      )}

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
        Current player {activePlayer.name}
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
