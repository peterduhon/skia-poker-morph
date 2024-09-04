import dotenv from "dotenv";
const alchemyKey = dotenv.REACT_APP_ALCHEMY_KEY;

import { createAlchemyWeb3 } from "@alch/alchemy-web3";
const web3 = createAlchemyWeb3(alchemyKey);

//import contractABI from "../contract-abi.json";
const contractAddress = "0x6f3f635A9762B47954229Ea479b4541eAF402A6A";

/* export const pokerContract = new web3.eth.Contract(
  contractABI,
  contractAddress
);
 */
