import React, { useState, useEffect, useCallback } from "react";
import {
  initializeXMTP,
  sendMessage,
  listenForMessages,
} from "../services/xmtpService";

// eslint-disable-next-line react/prop-types
export const PrivateMessaging = ({ signer, peerAddress }) => {
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState("");
  const [xmtpClient, setXmtpClient] = useState(null);

  useEffect(() => {
    const setup = async () => {
      const client = await initializeXMTP(signer);
      setXmtpClient(client);
    };
    setup();
  }, [signer]);

  useEffect(() => {
    if (!xmtpClient || !peerAddress) return;

    const unsubscribe = listenForMessages(peerAddress, (message) => {
      setMessages((prev) => [...prev, message]);
    });

    return unsubscribe;
  }, [xmtpClient, peerAddress]);

  const handleSend = useCallback(async () => {
    if (!newMessage.trim()) return;
    await sendMessage(peerAddress, newMessage);
    setNewMessage("");
  }, [newMessage, peerAddress]);

  return (
    <div className="private-messaging">
      <div className="message-list">
        {messages.map((msg, index) => (
          <div key={index} className="message">
            <span className="sender">
              {msg.senderAddress === xmtpClient.address ? "You" : "Peer"}:
            </span>
            <span className="content">{msg.content}</span>
          </div>
        ))}
      </div>
      <div className="message-input">
        <input
          type="text"
          value={newMessage}
          onChange={(e) => setNewMessage(e.target.value)}
          placeholder="Type a message..."
        />
        <button onClick={handleSend}>Send</button>
      </div>
    </div>
  );
};
