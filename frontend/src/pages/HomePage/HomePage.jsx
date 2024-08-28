import Web3 from "web3";
import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import "./home.scss";
import { MIN_PLAYERS } from "../../data/consts";
//import contract from "./contracts/NFTCollectible.json";

//const contractAddress = "djjj";
//const abi = contract.abi;

export const HomePage = () => {
  const [web3, setWeb3] = useState(null);
  //const [address, setAddress] = useState("");
  // const [balance, setBalance] = useState();

  const [userName, setUserName] = useState("");
  const users = 2;
  useEffect(() => {
    // ensure that there is an injected the Ethereum provider
    if (window.ethereum) {
      // use the injected Ethereum provider to initialize Web3.js
      setWeb3(new Web3("https://ropsten.infura.io"));

      //call smart contract - write user
      // read all users
      //getBalance();
    } else {
      console.log("Please install MetaMask!");
    }
  }, []);

  /* async function getBalance() {
    await window.ethereum.request({ method: "eth_requestAccounts" });
    const allAccounts = await web3.eth.getAccounts();
    setAddress(allAccounts[0]);
    //const balance = await web3.eth.getBalance(allAccounts[0]);
    //const ethBalance = web3.utils.toWei(balance, "ether");
    //setBalance(Math.round(ethBalance * 100) / 100);
    console.log(web3, "address", address);
  } */

  const navigate = useNavigate();

  const handleUser = () => {
    /// smart contract read users
    if (users >= MIN_PLAYERS) {
      navigate("game");
    }
  };

  if (web3) {
    return (
      <div>
        <form>
          <input
            type="text"
            name="user"
            value={userName}
            onChange={(e) => setUserName(e.target.value)}
          />
          <button type="submit" onClick={handleUser}>
            Add me
          </button>
        </form>
      </div>
    );
  } else {
    <div>Please install MetaMask!</div>;
  }
};
