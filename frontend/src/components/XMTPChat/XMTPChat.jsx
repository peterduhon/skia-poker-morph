import { useEffect, useState } from "react";
import {
  initializeXMTP,
  sendMessage,
  listenForMessages,
} from "../../services/xmtpService";
import Web3 from "web3";

// eslint-disable-next-line react/prop-types
export const XMTPChat = ({ web3auth, provider }) => {
  const [xmtpClient, setXmtpClient] = useState(null);
  const [messages, setMessages] = useState([]);

  useEffect(() => {
    if (provider) {
      // Use the connected provider instead of web3auth.provider
      const initXmtp = async () => {
        try {
          console.log("Web3Auth provider available, initializing XMTP...");
          const client = await initializeXMTP(provider);
          setXmtpClient(client);
        } catch (error) {
          console.error("Failed to initialize XMTP", error);
        }
      };
      initXmtp();
    } else {
      console.log("Connected Web3Auth provider not available yet");
    }
  }, [provider]);

  useEffect(() => {
    if (web3auth && provider) {
      const initXmtp = async () => {
        try {
          const signer = async (message) => {
            return web3auth.provider.request({
              method: "personal_sign",
              params: [
                message,
                await web3auth.provider
                  .request({ method: "eth_accounts" })
                  .then((accounts) => accounts[0]),
              ],
            });
          };
          const client = await initializeXMTP(signer);
          setXmtpClient(client);
        } catch (error) {
          console.error("Failed to initialize XMTP", error);
        }
      };
      initXmtp();
    } else {
      console.log("Web3Auth provider not available yet");
    }
  }, [web3auth]);

  const handleSendMessage = async (recipientAddress, messageContent) => {
    if (xmtpClient) {
      await sendMessage(recipientAddress, messageContent);
      setMessages((prevMessages) => [
        ...prevMessages,
        { type: "out", message: messageContent },
      ]);
    }
  };

  return (
    <>
      <button
        onClick={() => {
          handleSendMessage(
            "0xb58D9b6534aC12dD00257F53993e9f605Faa248A",
            "Hello from Tetiana to Pete!"
          );
        }}
      >
        Send message from Player1 to Player2
      </button>
      <div>
        {messages.map((message) => (
          <p key={message}>{message}</p>
        ))}
      </div>
    </>
  );
};
