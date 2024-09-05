import { Client } from "@xmtp/xmtp-js";
import { ethers } from "ethers";

let xmtp;
let conversations = new Map();

export const initializeXMTP = async (signer) => {
  xmtp = await Client.create(signer, { env: "production" });
  return xmtp;
};

export const startConversation = async (peerAddress) => {
  if (!xmtp) throw new Error("XMTP client not initialized");
  const conversation = await xmtp.conversations.newConversation(peerAddress);
  conversations.set(peerAddress, conversation);
  return conversation;
};

export const sendMessage = async (peerAddress, message) => {
  const conversation =
    conversations.get(peerAddress) || (await startConversation(peerAddress));
  await conversation.send(message);
};

export const listenForMessages = (peerAddress, callback) => {
  const conversation = conversations.get(peerAddress);
  if (!conversation) throw new Error("Conversation not found");

  const stream = conversation.streamMessages();
  stream.on("message", callback);
  return () => stream.return(); // Call this function to stop listening
};
