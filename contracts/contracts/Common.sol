pragma solidity ^0.8.19;

// Enums
enum Suit { Spades, Hearts, Diamonds, Clubs }
enum Value { Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace }
enum GameState {
    WaitingForPlayers,
    PreFlop,
    Flop,
    Turn,
    River,
    Showdown,
    Finished
}
enum PlayerAction {
    None,
    Fold,
    Check,
    Call,
    Bet,
    Raise,
    AllIn,
    Begin // Added 'Begin' to combine with previous definition
}
enum HandRanking {
    HighCard,
    OnePair,
    TwoPairs,
    ThreeOfAKind,
    Straight,
    Flush,
    FullHouse,
    FourOfAKind,
    StraightFlush,
    RoyalFlush
}
enum GameStatus { Waiting, Active, Completed }

// Structs
struct Card {
    Suit suit;
    Value value;
}

struct Player {
    address addr; // Renamed to avoid confusion with PlayerInfo
    uint256 balance; // You may want to consider using 'chips' for clarity across structs
    uint256 currentBet;
    PlayerAction action; // You may want to consider renaming to 'status' for consistency
    bool isActive;
    bool hasActed;
}

struct Pot {
    uint256 amount;
    address[] eligiblePlayers;
}

struct GameRoom {
    uint256 id;
    address creator;
    uint256 buyInAmount;
    uint256 maxPlayers;
    uint256 createdAt;
    GameStatus status;
}

struct Room {
    uint256 id;
    uint256 buyInAmount;
    mapping(address => PlayerInfo) playerInfos;
    address[] players;
}

struct PlayerInfo {
    string nickName;
    uint256 chips;
}

struct User {
    address userAddress;
    string username;
    uint256 balance;
}
