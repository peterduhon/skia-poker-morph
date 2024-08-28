import { useContext } from "react";
import { AuthContext } from "../../App";

export const Navbar = () => {
  const context = useContext(AuthContext);
  return (
    <button
      className="btn btn-outline-secondary login-btn"
      onClick={context.mmLogin}
    >
      <img
        className="top arcade-frame"
        src=""
        alt=""
        height="25px"
        width="25px"
      />
      <span> Connect Wallet</span>
    </button>
  );
};
