import { useState, useEffect } from "react";
import { Web3Auth } from "@web3auth/modal";
import { CHAIN_NAMESPACES } from "@web3auth/base";
import { Button, Container, Typography } from "@mui/material";
import { Wallet } from "lucide-react";
import { EthereumPrivateKeyProvider } from "@web3auth/ethereum-provider";
import Web3 from "web3";

const clientId = import.meta.env.VITE_APP_WEB3AUTH_CLIENT_ID; // Make sure this is set in your .env file

const chainConfig = {
  chainNamespace: CHAIN_NAMESPACES.EIP155,
  chainId: "0xAFA",
  rpcTarget: "https://rpc-quicknode-holesky.morphl2.io/",
  // Avoid using public rpcTarget in production.
  // Use services like Infura, Quicknode etc
  displayName: "Morph Holesky Testnet",
  blockExplorerUrl: "https://explorer.morph.network",
  ticker: "ETH",
  tickerName: "Ethereum",
  logo: "https://cryptologos.cc/logos/ethereum-eth-logo.png",
};

const privateKeyProvider = new EthereumPrivateKeyProvider({
  config: { chainConfig },
});

export const AuthPage = () => {
  const [web3auth, setWeb3auth] = useState(null);
  const [provider, setProvider] = useState(null);
  const [userAddress, setUserAddress] = useState(null);

  useEffect(() => {
    const init = async () => {
      try {
        const web3auth = new Web3Auth({
          clientId,
          web3AuthNetwork: "testnet",
          privateKeyProvider: privateKeyProvider,
          uiConfig: {
            theme: "dark",
            loginMethodsOrder: ["google"],
          },
        });
        setWeb3auth(web3auth);
        await web3auth.initModal();
        setProvider(web3auth.provider);
        web3auth.on("connected", (data) => console.log("connected", data));
        web3auth.on("connecting", () => console.log("connecting"));
        web3auth.on("disconnected", () => console.log("disconnected"));
        web3auth.on("errored", (error) => console.error("error", error));

        setWeb3auth(web3auth);
      } catch (error) {
        console.error(error);
      }
    };
    init();
  }, []);

  const connect = async () => {
    if (!web3auth) {
      console.log("Web3Auth not initialized yet");
      return;
    }
    try {
      // Connect to Web3Auth
      const web3authProvider = await web3auth.connect();
      setProvider(web3authProvider); // Set provider in state
      console.log("Connection successful, provider:", web3authProvider);

      // Create a Web3 instance using the provider from Web3Auth
      const web3 = new Web3(web3authProvider);

      // Get the user's Ethereum accounts
      const accounts = await web3.eth.getAccounts();
      const userAddress = accounts[0]; // Get the first account (user's address)
      setUserAddress(userAddress); // Save the user's address to state
      console.log("User's Ethereum address:", userAddress);
    } catch (error) {
      console.error("Connection error:", error);
    }
  };

  return (
    <Container className="h-screen flex flex-col justify-center items-center">
      <Typography variant="h2" className="mb-8">
        Welcome to Skia Poker
      </Typography>
      <Button
        variant="contained"
        startIcon={<Wallet />}
        onClick={connect}
        className="bg-blue-500 hover:bg-blue-700"
      >
        Connect with Google
      </Button>
    </Container>
  );
};
