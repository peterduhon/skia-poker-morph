// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
contract PokerGame is VRFConsumerBase {

    enum PlayerAction {
        Call,
        Raise,
        Check,
        Fold
    }
    enum Suit { Spades, Hearts, Diamonds, Clubs }
    enum Value { Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace }

event NewTableCreated(uint tableId, Table table);
event PlayerRegistered(address Player);
event GameStarted(uint tableId);
event PlayerJoined(uint tableId, address player);
event GameEnded(uint tableId, address winner);
event getRandom(uint256);

struct Table {
        uint currentRound; // index of the current round
        address[] players;
     }

     struct Round {
        address[] players; 
        uint highestChip; 
        uint[] chips; 
    }

    struct Card {
        Suit suit;
        Value value;
    }

    struct PlayerCards {
        Card card1;
        Card card2;
    }

    struct Player {
        uint256 balance;
        bool folded;
     }

    
    bytes32 internal keyHash;
    uint256 internal fee;
    address vrfCoordinator;
    address linkToken;
    uint256 public  randomnessResul;
    uint public totalTables;

    mapping (address => Player) public players;
    mapping(address => uint) public balances;
     mapping(uint => Table) public tables;
     mapping(address => mapping(uint => uint)) public chips;  //player => tableId => remainingChips
     mapping(uint => mapping(uint => Round)) public rounds;  //tableId => roundNum => Round
  mapping(uint => uint8[]) public communityCards; // tableId => int8[] community cards

    // Game state variables here

    constructor(
        address _vrfCoordinator, 
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {   // HERE I dont understand _vrfCoordinator, _linkToken shoulld be given
        keyHash = _keyHash;
        fee = _fee;
        
    }
function registerPlayer() external{
    require(!players[msg.sender], "Player already registered");
    players[msg.sender] = Player({
            balance: 0,
            folded: false
           
        });
    emit PlayerRegistered(msg.sender);
}

    function joinGame() public payable {
        require(msg.value == 1 ether, "Entry fee is 1 ETH");
        players.push(msg.sender);
    }
    function startGame() public {
        // Ensure sufficient players and start game logic
        requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // Use randomness to shuffle and deal cards
        randomnessResul = randomness;        /// HERE what is randomness and how it use 
        emit getRandom(randomness);
    }
    function determineWinner() public view returns (address) {
        // Logic to determine the winner
    }

    function distributeWinnings() public {
        // Logic to distribute winnings
    }

    function createTable() external {
       
       address[] memory empty;
       
        tables[totalTables] =  Table({
            currentRound: 0,
            players: empty
     });

        emit NewTableCreated(totalTables, tables[totalTables]);

        totalTables += 1;
    }
}
