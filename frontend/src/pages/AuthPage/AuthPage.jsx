import { useState, useEffect } from "react";
import { Web3Auth } from "@web3auth/modal";
import { CHAIN_NAMESPACES, WEB3AUTH_NETWORK } from "@web3auth/base";
import { Button, Container, Typography } from "@mui/material";
import { Wallet } from "lucide-react";
import { EthereumPrivateKeyProvider } from "@web3auth/ethereum-provider";

const clientId = import.meta.env.VITE_APP_WEB3AUTH_CLIENT_ID; // Make sure this is set in your .env file

const chainConfig = {
  chainNamespace: CHAIN_NAMESPACES.EIP155,
  chainId: "0x89",
  rpcTarget: "https://rpc.morph.network",
  // Avoid using public rpcTarget in production.
  // Use services like Infura, Quicknode etc
  displayName: "Morph Testnet",
  blockExplorerUrl: "https://explorer.morph.network",
  ticker: "MORPH",
  tickerName: "Morph Token",
  logo: "https://cryptologos.cc/logos/ethereum-eth-logo.png",
};

const privateKeyProvider = new EthereumPrivateKeyProvider({
  config: { chainConfig },
});

export const AuthPage = () => {
  const [web3auth, setWeb3auth] = useState(null);
  const [provider, setProvider] = useState(null);

  useEffect(() => {
    const init = async () => {
      try {
        const web3auth = new Web3Auth({
          clientId,
          web3AuthNetwork: WEB3AUTH_NETWORK.SAPPHIRE_DEVNET,
          privateKeyProvider,
          uiConfig: {
            theme: "dark",
            loginMethodsOrder: ["google"],
          },
        });
        setWeb3auth(web3auth);
        await web3auth.initModal();
        setProvider(web3auth.provider);
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
    const web3authProvider = await web3auth.connect();
    setProvider(web3authProvider);
    //onConnect(web3authProvider);
  };

  console.log("web3auth", web3auth);
  console.log("provider", provider);

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
