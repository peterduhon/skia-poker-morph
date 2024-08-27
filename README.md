# Skia Poker

Skia Poker is a decentralized poker game built on the Morph zkEVM platform, leveraging blockchain technology and zero-knowledge proofs to provide a fair, secure, and transparent gaming experience. The project aims to revolutionize the online poker landscape by addressing the challenges of fraud and trust in traditional Web2 poker platforms.

## Project Goals

### PRD1
- Develop a fully decentralized poker game with smart contracts managing gameplay and player interactions
- Integrate Chainlink VRF for provably fair random number generation
- Create an intuitive and responsive user interface for seamless gameplay
- Ensure compatibility with popular Web3 wallets (MetaMask, Coinbase, Rainbow) for secure authentication and transactions
- Implement Web3Auth for a seamless and secure authentication experience

### PRD2
- Introduce AI-powered opponents using Galadriel AI for challenging gameplay
- Implement secure messaging using XMTP for player communication
- Integrate POKT Network for decentralized infrastructure and improved performance
- Explore cross-chain capabilities with Axelar Network for asset transfer and interoperability

## Technology Stack

- Morph zkEVM: Blockchain platform for deploying smart contracts
- Chainlink VRF: Verifiable random number generation for fair gameplay
- React: Frontend framework for building the user interface
- Web3.js: Library for interacting with the Ethereum blockchain
- Web3Auth: Secure wallet authentication and management
- XMTP: Decentralized messaging protocol for secure player communication
- Galadriel AI: Platform for creating intelligent poker agents
- POKT Network: Decentralized infrastructure for improved performance and reliability
- Axelar Network: Cross-chain communication and asset transfer capabilities

## Project Structure

- `contracts/`: Solidity smart contracts for gameplay and player management
- `frontend/`: React frontend code for the user interface
- `backend/`: Backend services and APIs (if applicable)
- `docs/`: Project documentation, including meeting notes and research spikes
- `resources/`: Project resources, including PRDs, project brief, and coding resource document

## Development Tracking

We use GitHub Issues to track development tickets and spikes. Each ticket or spike will be created as an issue, assigned to the appropriate team member, and labeled accordingly. Progress and discussions related to each ticket or spike will be managed within the respective issue.

## Getting Started

1. **Clone the repository:**
   - Use the following command to clone the repository to your local machine:
     ```bash
     git clone https://github.com/peterduhon/skia-poker-morph.git
     ```
   - Navigate to the project directory:
     ```bash
     cd skia-poker-morph
     ```

2. **Install the necessary dependencies for the frontend:**
   - Navigate to the `frontend/` directory:
     ```bash
     cd frontend
     ```
   - Install the required npm packages:
     ```bash
     npm install
     ```
   - Return to the main project directory:
     ```bash
     cd ..
     ```

3. **Install the necessary dependencies for the backend:**
   - Navigate to the `backend/` directory:
     ```bash
     cd backend
     ```
   - Install the required npm packages (or other package manager if applicable):
     ```bash
     npm install
     ```
   - Return to the main project directory:
     ```bash
     cd ..
     ```

4. **Set up the development environment:**
   - Ensure you have the necessary tools installed, such as Node.js, npm, and a Solidity development environment like Hardhat or Truffle.
   - Configure environment variables (if applicable) in a `.env` file. Example:
     ```env
     REACT_APP_WEB3AUTH_CLIENT_ID=your_web3auth_client_id
     REACT_APP_CHAIN_ID=your_chain_id
     ```
   - For backend services, configure any necessary API keys or database connections.

5. **Compile and deploy the smart contracts:**
   - Navigate to the `contracts/` directory:
     ```bash
     cd contracts
     ```
   - Compile the smart contracts:
     ```bash
     npx hardhat compile
     ```
   - Deploy the contracts to the Morph zkEVM testnet:
     ```bash
     npx hardhat run scripts/deploy.js --network testnet
     ```
   - Ensure to replace `testnet` with the actual network configuration if using a different network.

6. **Run the frontend application:**
   - Navigate back to the `frontend/` directory:
     ```bash
     cd frontend
     ```
   - Start the development server:
     ```bash
     npm start
     ```

7. **Run the backend application (if applicable):**
   - Navigate to the `backend/` directory:
     ```bash
     cd backend
     ```
   - Start the backend server:
     ```bash
     npm start
     ```

8. **Access the application:**
   - Once the frontend server is running, open your web browser and navigate to `http://localhost:3000` to see the Skia Poker interface.

## Contributing

We welcome contributions from the community! If you'd like to contribute to Skia Poker, please follow these steps:

1. Fork the repository
2. Create a new branch for your feature or bug fix
3. Commit your changes and push the branch to your fork
4. Submit a pull request, describing your changes and their purpose

Please make sure to adhere to the project's coding standards and guidelines, and include appropriate tests and documentation with your contributions.

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more information.

## Contact

If you have any questions, suggestions, or feedback, please feel free to reach out to the project maintainers:

- Pete (Product Manager): [email@example.com](mailto:email@example.com)
- James (Full Stack Developer): [email@example.com](mailto:email@example.com)

Let's revolutionize the online poker experience together with Skia Poker!
