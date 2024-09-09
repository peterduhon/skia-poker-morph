import { Client } from "@xmtp/xmtp-js";
import Web3 from "web3";

let xmtp;

export const initializeXMTP = async (provider) => {
  try {
    console.log("Initializing XMTP with Web3Auth provider...");
    const web3 = new Web3(provider);
    const accounts = await web3.eth.getAccounts();
    console.log("Signer account:", accounts[0]);

    const signer = {
      getAddress: async () => accounts[0],
      signMessage: async (message) => {
        console.log("Signing message:", message);
        const signature = await web3.eth.personal.sign(message, accounts[0]);
        console.log("Generated signature:", signature);
        return signature;
      },
    };

    console.log("Creating XMTP client...");
    const client = await Client.create(signer, { env: "production" });
    console.log("XMTP client created successfully");
    return client;
  } catch (error) {
    console.error("XMTP Client creation failed", error);
    throw error;
  }
};

export const sendMessage = async (peerAddress, message) => {
  if (!xmtp) throw new Error("XMTP client not initialized");
  const conversation = await xmtp.conversations.newConversation(peerAddress);
  await conversation.send(message);
};

export const listenForMessages = (callback) => {
  if (!xmtp) throw new Error("XMTP client not initialized");
  const stream = xmtp.conversations.streamAllMessages();
  stream.on("message", callback);
  return () => stream.removeListener("message", callback);
};
