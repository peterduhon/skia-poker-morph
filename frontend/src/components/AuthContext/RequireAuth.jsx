import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useContext } from "react";
import { AuthContext } from "./AuthContext";

// eslint-disable-next-line react/prop-types
export const RequireAuth = ({ children }) => {
  const { userAddress } = useContext(AuthContext);
  const location = useLocation();
  console.log(userAddress);
  if (!userAddress) {
    return <Navigate to="/auth" state={{ from: location }} replace />;
  }

  return children || <Outlet />;
};
