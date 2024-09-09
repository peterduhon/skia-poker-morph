import React, { useState, useMemo } from "react";

export const AuthContext = React.createContext({});

// eslint-disable-next-line react/prop-types
export const AuthProvider = ({ children }) => {
  const [web3auth, setWeb3auth] = useState(null);
  const [provider, setProvider] = useState(null);
  const [userAddress, setUserAddress] = useState(null);

  const value = useMemo(
    () => ({
      web3auth,
      provider,
      userAddress,
      setWeb3auth,
      setProvider,
      setUserAddress,
    }),
    [provider, userAddress, web3auth]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
