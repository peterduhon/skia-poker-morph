import React, { createContext, useState, useContext } from "react";

const Web3Context = createContext();

export const Web3Provider = ({ children }) => {
  const [web3, setWeb3] = useState(null);
  const [address, setAddress] = useState("");

  return (
    <Web3Context.Provider value={{ web3, setWeb3, address, setAddress }}>
      {children}
    </Web3Context.Provider>
  );
};

export const useWeb3 = () => useContext(Web3Context);
