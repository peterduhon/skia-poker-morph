\# HandEvaluator Contract Variables  
handEvaluator:  
  gameState:  
    buyInAmount: uint256  \# Amount required to buy into the game  
    currentPot: uint256   \# Current total pot for the game  
    mainPot: uint256      \# Main pot for the game  
    gameActive: bool      \# Whether a game is currently active  
    currentPlayerIndex: uint256  \# Index of the current player's turn  
    currentBet: uint256   \# Current bet amount  
    communityCardCount: uint256  \# Number of community cards dealt  
    roundNumber: uint256  \# Current round number  
    currentPhase: GamePhase  \# Current phase of the game  
  playerManagement:  
    playerAddresses: address\[\]  \# Array of player addresses  
    players: mapping(address \=\> Player)  \# Mapping of player addresses to Player structs  
  cardManagement:  
    deck: uint256\[\]  \# The deck of cards  
    communityCards: Card\[5\]  \# Array of community cards  
  bettingManagement:  
    sidePots: SidePot\[\]  \# Array of side pots for all-in situations

\# GameManagement Contract Variables  
gameManagement:  
  gameRoomManagement:  
    nextGameId: uint256  \# ID for the next game to be created  
    gameRooms: mapping(uint256 \=\> GameRoom)  \# Mapping of game IDs to GameRoom structs  
    userGames: mapping(address \=\> uint256\[\])  \# Mapping of user addresses to arrays of their game IDs

\# UserManagement Contract Variables  
userManagement:  
  userData:  
    users: mapping(address \=\> User)  \# Mapping of user addresses to User structs  
