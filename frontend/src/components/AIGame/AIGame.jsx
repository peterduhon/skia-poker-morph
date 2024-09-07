import { useEffect, useState } from "react";
import "./game.scss";
import { Player } from "../Player/Player";
import { CommunityCards } from "../CommunityCards/CommunityCard";

/* //frontend listen to players, currentPlayer, phase, communityCards */
let phase = "pre-flop";
const currentPlayer = "Peter";
const users = [
  { name: "Peter", cards: ["op", "jk"] },

  { name: "AI", cards: ["kl", "hj"] },
];

const communityCards = ["gh", "fg", "jk", "hj", "hj"];

export const AIGame = () => {
  const [walletAddress, setWallet] = useState("");
  const [status, setStatus] = useState("");

  useEffect(() => {
    //TODO: implement
    initialWallet();
  }, []);

  async function initialWallet() {
    const { address, status } = await getCurrentWalletConnected();

    setWallet(address);
    setStatus(status);

    addWalletListener();
  }

  function addWalletListener() {
    if (window.ethereum) {
      window.ethereum.on("accountsChanged", (accounts) => {
        if (accounts.length > 0) {
          setWallet(accounts[0]);
          setStatus("👆🏽 Write a message in the text-field above.");
        } else {
          setWallet("");
          setStatus("🦊 Connect to Metamask using the top right button.");
        }
      });
    } else {
      setStatus(
        <p>
          {" "}
          🦊{" "}
          <a target="_blank" href={`https://metamask.io/download.html`}>
            You must install Metamask, a virtual Ethereum wallet, in your
            browser.
          </a>
        </p>
      );
    }
  }

  const getCurrentWalletConnected = async () => {
    if (window.ethereum) {
      try {
        const addressArray = await window.ethereum.request({
          method: "eth_accounts",
        });
        if (addressArray.length > 0) {
          return {
            address: addressArray[0],
            status: "👆🏽 Write a message in the text-field above.",
          };
        } else {
          return {
            address: "",
            status: "🦊 Connect to Metamask using the top right button.",
          };
        }
      } catch (err) {
        return {
          address: "",
          status: "😥 " + err.message,
        };
      }
    } else {
      return {
        address: "",
        status: (
          <span>
            <p>
              {" "}
              🦊{" "}
              <a target="_blank" href={`https://metamask.io/download.html`}>
                You must install Metamask, a virtual Ethereum wallet, in your
                browser.
              </a>
            </p>
          </span>
        ),
      };
    }
  };

  const connectWalletPressed = async () => {
    const walletResponse = await connectWallet();
    setStatus(walletResponse.status);
    setWallet(walletResponse.address);
  };

  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        const addressArray = await window.ethereum.request({
          method: "eth_requestAccounts",
        });
        const obj = {
          status: "👆🏽 Write a message in the text-field above.",
          address: addressArray[0],
        };
        return obj;
      } catch (err) {
        return {
          address: "",
          status: "😥 " + err.message,
        };
      }
    } else {
      return {
        address: "",
        status: (
          <span>
            <p>
              {" "}
              🦊{" "}
              <a target="_blank" href={`https://metamask.io/download.html`}>
                You must install Metamask, a virtual Ethereum wallet, in your
                browser.
              </a>
            </p>
          </span>
        ),
      };
    }
  };

  return (
    <>
      <button id="walletButton" onClick={connectWalletPressed}>
        {walletAddress.length > 0 ? (
          "Connected: " +
          String(walletAddress).substring(0, 6) +
          "..." +
          String(walletAddress).substring(38)
        ) : (
          <span>Connect Wallet</span>
        )}
      </button>
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
