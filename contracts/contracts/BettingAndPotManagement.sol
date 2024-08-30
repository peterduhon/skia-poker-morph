// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ICardManagement.sol";
import "./interfaces/IGameMechanics.sol";
import "./UserManagement.sol";

contract BettingAndPotManagement is Ownable, ReentrancyGuard {
    enum Phase { NotStarted, Registration, BuyIn, Betting, Showdown }
    Phase public currentPhase;

    address public cardManagementAddress;
    address public gameMechanicsAddress;
    address public userManagementAddress;

    struct Player {
        uint256 chips;
        bool isActive;
        uint256 currentBet;
    }

    struct Card {
        uint8 rank;
        uint8 suit;
    }

    mapping(address => Player) public players;
    address[] public activePlayers;
    uint256 public totalPot;
    uint256 public currentBet;

    modifier onlyDuringPhase(Phase phase) {
        require(currentPhase == phase, "Invalid phase");
        _;
    }

    event BetPlaced(address indexed player, uint256 amount);
    event PlayerFolded(address indexed player);
    event PlayerCalled(address indexed player, uint256 amount);
    event PlayerRaised(address indexed player, uint256 amount);
    event PlayerAllIn(address indexed player, uint256 amount);
    event SidePotDistributed(uint256 indexed sidePotIndex, address[] winners, uint256 share);
    event PotDistributed(address[] winners, uint256 share);

    constructor(
        address _cardManagementAddress,
        address _gameMechanicsAddress,
        address _userManagementAddress
    ) {
        cardManagementAddress = _cardManagementAddress;
        gameMechanicsAddress = _gameMechanicsAddress;
        userManagementAddress = _userManagementAddress;
    }

    function collectBuyIns() external onlyOwner onlyDuringPhase(Phase.Registration) {
        IGameMechanics gameMechanics = IGameMechanics(gameMechanicsAddress);
        address[] memory playersList = gameMechanics.getAllPlayers();
        uint256 buyInAmount = gameMechanics.getBuyInAmount();

        for (uint256 i = 0; i < playersList.length; i++) {
            address player = playersList[i];
            players[player].chips = buyInAmount;
            players[player].isActive = true;
            activePlayers.push(player);
        }
        currentPhase = Phase.BuyIn;
    }

    function resetRound() internal {
        totalPot = 0;
        currentBet = 0;

        for (uint256 i = 0; i < activePlayers.length; i++) {
            address player = activePlayers[i];
            players[player].currentBet = 0;
        }
    }

    function endCurrentRound() external onlyOwner onlyDuringPhase(Phase.Betting) {
        for (uint256 i = 0; i < activePlayers.length; i++) {
            address player = activePlayers[i];
            if (players[player].currentBet < currentBet) {
                revert("Not all players have matched the current bet");
            }
        }
        currentPhase = Phase.Showdown;
    }

    function advancePhase() external onlyOwner onlyDuringPhase(Phase.Betting) {
        currentPhase = Phase(uint256(currentPhase) + 1);
    }

    function placeBet(uint256 amount) external onlyDuringPhase(Phase.Betting) {
        address player = msg.sender;
        require(players[player].isActive, "Player is not active");
        require(players[player].chips >= amount, "Insufficient chips");

        uint256 betAmount = amount > currentBet ? amount - currentBet : 0;
        players[player].chips -= betAmount;
        players[player].currentBet += betAmount;
        totalPot += betAmount;
        currentBet = amount;

        emit BetPlaced(player, amount);

        if (players[player].currentBet == players[player].chips) {
            fold(player);
        }
    }

    function fold(address player) public onlyDuringPhase(Phase.Betting) {
        require(players[player].isActive, "Player is not active");

        players[player].isActive = false;
        for (uint256 i = 0; i < activePlayers.length; i++) {
            if (activePlayers[i] == player) {
                activePlayers[i] = activePlayers[activePlayers.length - 1];
                activePlayers.pop();
                emit PlayerFolded(player);
                break;
            }
        }
    }

    function call() external onlyDuringPhase(Phase.Betting) {
        address player = msg.sender;
        require(players[player].isActive, "Player is not active");
        uint256 betAmount = currentBet - players[player].currentBet;

        require(players[player].chips >= betAmount, "Insufficient chips");
        players[player].chips -= betAmount;
        players[player].currentBet += betAmount;
        totalPot += betAmount;

        emit PlayerCalled(player, betAmount);
    }

    function raise(uint256 amount) external onlyDuringPhase(Phase.Betting) {
        address player = msg.sender;
        require(players[player].isActive, "Player is not active");

        uint256 betAmount = amount > currentBet ? amount - currentBet : 0;
        require(players[player].chips >= betAmount, "Insufficient chips");

        players[player].chips -= betAmount;
        players[player].currentBet += betAmount;
        totalPot += betAmount;
        currentBet = amount;

        emit PlayerRaised(player, amount);
    }

    function handleAllIn(uint256 amount) external onlyDuringPhase(Phase.Betting) {
        address player = msg.sender;
        require(players[player].isActive, "Player is not active");

        uint256 betAmount = amount > players[player].chips ? players[player].chips : amount;
        players[player].currentBet += betAmount;
        players[player].chips -= betAmount;
        totalPot += betAmount;
        fold(player);

        emit PlayerAllIn(player, betAmount);
    }

    function removePlayerFromActiveList(address player) external onlyOwner onlyDuringPhase(Phase.Betting) {
        require(players[player].isActive, "Player is not active");
        players[player].isActive = false;

        for (uint256 i = 0; i < activePlayers.length; i++) {
            if (activePlayers[i] == player) {
                activePlayers[i] = activePlayers[activePlayers.length - 1];
                activePlayers.pop();
                emit PlayerFolded(player);
                break;
            }
        }
    }

    function startNewRound() external onlyOwner onlyDuringPhase(Phase.Showdown) {
        currentPhase = Phase.Betting;
        resetRound();
    }

    function endGame() external onlyOwner onlyDuringPhase(Phase.Showdown) {
        IGameMechanics gameMechanics = IGameMechanics(gameMechanicsAddress);
        gameMechanics.endGame();

        currentPhase = Phase.NotStarted;
    }

    function determineWinners() internal view onlyOwner returns (address[] memory) {
        IGameMechanics gameMechanics = IGameMechanics(gameMechanicsAddress);
        ICardManagement cardManagement = ICardManagement(cardManagementAddress);
        
        address[] memory playersList = gameMechanics.getAllPlayers();
        uint256 highestHandValue = 0;
        address[] memory winners = new address[](playersList.length);
        uint256 winnerCount = 0;

        for (uint256 i = 0; i < playersList.length; i++) {
            address player = playersList[i];
            if (!players[player].isActive) continue;

            // Get player's hand and evaluate it
            Card[] memory hand = gameMechanics.getPlayerHand(player);
            uint256 handValue = cardManagement.evaluateHand(hand);

            if (handValue > highestHandValue) {
                highestHandValue = handValue;
                winnerCount = 0;
                winners[winnerCount] = player;
                winnerCount++;
            } else if (handValue == highestHandValue) {
                winners[winnerCount] = player;
                winnerCount++;
            }
        }

        // Resize the winners array to the actual number of winners
        address[] memory finalWinners = new address[](winnerCount);
        for (uint256 i = 0; i < winnerCount; i++) {
            finalWinners[i] = winners[i];
        }

        return finalWinners;
    }

    function distributePots() internal onlyOwner onlyDuringPhase(Phase.Showdown) {
        address[] memory winners = determineWinners();
        uint256 share = totalPot / winners.length;

        for (uint256 i = 0; i < winners.length; i++) {
            address winner = winners[i];
            payable(winner).transfer(share);
        }

        emit PotDistributed(winners, share);

        // Reset pot
        totalPot = 0;
    }

    function resetBettingRound() external onlyOwner onlyDuringPhase(Phase.Betting) {
        resetRound();
    }
}
