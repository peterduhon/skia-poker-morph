import "./game.scss";
import { Player } from "../../components/Player/Player";
import { CommunityCards } from "../../components/CommunityCards/CommunityCard";
import UserManagementABI from "../../contracts/UserManagement.json";
import Web3 from "web3";

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

/* const web3 = new Web3("https://rpc.ankr.com/eth_holesky");
const contractUserAddress = "0x8EE046ef044C7fd8D41777259024f6d52Ba1d5b4";
const userManagement = new web3.eth.Contract(
  UserManagementABI,
  contractUserAddress
); */
/* userManagement.methods     ///already tested
  .isUserRegistered("0xC85eCEAbf9A7c78C4F0D8Dfca2A84BA661bcB84F")
  .call()
  .then(console.log); */

/* userManagement.methods // call smart contract to register user
  .registerUser("Mark")
  .send({
    from: "0x98cD47bE93b3c28fD436d000FED9B9935b00660F",
    value: web3.utils.toWei("0.1", "ether"),
  }); */

//call function that change state
/*  await userManagement.methods // call smart contract to register user
        .registerUser("Mark")
        .send({ from: userAddress, value: web3.utils.toWei("0.1", "ether") }); */

// listen to events
/* await userManagement.events // call smart contract to register user
  .UserRegistered({}, (error, event) => {
    if (error) {
      console.error("user event Error:", error);
      return;
    }

    console.log("New event received:");
    console.log(event.returnValues);
  })
  .on("connected", () => {
    console.log("Connected to the blockchain");
  })
  .on("changed", (event) => {
    console.log("Event changed:", event.returnValues);
  })
  .on("error", (error) => {
    console.error("Event error:", error);
  }); */

export const Game = () => {
  return (
    <>
      <div
        style={{
          gridColumn: 2,
          gridRow: 1,
          display: "flex",
          justifyContent: "space-between",
        }}
      >
        <div
          style={{
            gridColumn: 2,
            gridRow: 1,
            maxWidth: 150,
            backgroundColor: "yellow",
            padding: 10,
          }}
        >
          Current player {currentPlayer}
        </div>
        <div
          style={{
            gridColumn: 6,
            gridRow: 1,
            maxWidth: 80,
            backgroundColor: "yellow",
            padding: 10,
          }}
        >
          {phase}
        </div>
        <div
          className="actions"
          style={{ gridColumn: 11, gridRow: 1, maxWidth: 200 }}
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
      </div>
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
    </>
  );
};
