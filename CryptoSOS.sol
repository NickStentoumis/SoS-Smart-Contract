// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CryptoSOS {
    // owner of the contract
    address public owner;

    // player one of SOS game
    address public player1;

    // player two of SOS game
    address public player2;

    // variable the stores the time of the last move
    uint256 public lastMoveTime;

    // variable that stores the start time of the game
    uint256 public gameStartTime;

    // bool variable(true or false that stores whether the game is active or not)
    bool public isGameActive;

    // variable that stores the time the last game ended
    uint256 public lastGameEndTime;
    
    // enum variable that stores the three possible states of the board
    enum Symbol { Empty, S, O }

    // the main board of the game
    Symbol[9] public board;

    // address of the player currently playing
    address public currentPlayer;
    
    // all the events that might emit during the game
    event StartGame(address indexed player1, address indexed player2);
    event Move(address indexed player, uint8 indexed position, uint8 symbol);
    event Winner(address indexed winner);
    event Tie(address indexed player1, address indexed player2);

    // constructor is called with the deployment of the contract and assigns the address of the sender to the owner variable
    constructor() {
        owner = msg.sender;
    }
    
    // modifier that checks whether the sender of a function is one of the players participating in the game
    modifier playersOnly() {
        require(msg.sender == player1 || msg.sender == player2, "Sender is not one of the players");
        _;
    }
    
    // modifier that checks if the sender of a function is the owner
    modifier ownerOnly() {
        require(msg.sender == owner, "Sender is not the owner");
        _;
    }
    
    // modifier that checks if the game is in progress
    modifier gameInProgress() {
        require(isGameActive, "There is no active game");
        _;
    }

    // modifier that checks if the sender of a function is player 1
    modifier player1Only() {
        require(msg.sender == player1, "Only player1 can call this function");
        _;
    }

    // function used to join the SOS game
    function join() external payable {
        
        // 1 ether needed to join the game
        require(msg.value == 1 ether, "Please send exactly 1 Ether to join the game");
        
        // cannot join the game if two players already joined
        require(player1 == address(0) || player2 == address(0), "The game is already in progress");
        
        // Next game cannot start as soon as the current game end.
        require(block.timestamp >= lastGameEndTime + 10, "Last game just ended. Wait before starting a new one");
        
        // if player's one address is empty
        if (player1 == address(0)) {

            // add the address to player1 variable
            player1 = msg.sender;

            //emit the StartGame event, only with address of player1
            emit StartGame(player1, address(0));

        // if address of player 2 is empty and the sender is not player one    
        } else if (player2 == address(0) && msg.sender != player1) {

            //add sender address to player 2 variable
            player2 = msg.sender;

            // game is now active, since both players joined
            isGameActive = true;

            //first player to make a move, is player 1
            currentPlayer = player1;

            //set start time of the game
            gameStartTime = block.timestamp;

            // emit Start game event, this time with the addresses of both the players
            emit StartGame(player1, player2);

        // Cannot play against yourself exception    
        } else {
            revert("You cannot play against yourself. Another player needs to join.");
        }
    }
    
    //function to place an S to the board. Requires game to be in progress and to be called by one of the two registered players
    function placeS(uint8 position) external gameInProgress playersOnly {
        makeMove(position, Symbol.S);
    }
    
    //function to place an O to the board. Requires game to be in progress and to be called by one of the two registered players
    function placeO(uint8 position) external gameInProgress playersOnly {
        makeMove(position, Symbol.O);
    }
    
    //function that places a symbol to the game board
    function makeMove(uint8 position, Symbol symbol) internal {

        //needs to be your turn to make a move
        require(msg.sender == currentPlayer, "Sorry, not your turn");
        
        // position needs to be between 1 and 9, else throw an error
        require(position >= 1 && position <= 9, "Position entered is not valid");
        
        //cannot add S or O to a position that is not empty
        require(board[position - 1] == Symbol.Empty, "Position already taken");
        
        // if all prerequisites are met, then place the symbol to board
        board[position - 1] = symbol;

        // change the timestamp of lastmove
        lastMoveTime = block.timestamp;

        // emit a move event. Casting the enum symbol converts it to the corresponding number it has in the list
        emit Move(msg.sender, position, uint8(symbol));
        
        // check if there is a winner
        if (declareWinner()) {

            //if there is a winner the declareWinner returns true and the declareGameover function is called to end the game
            declareGameOver(msg.sender);
        } else if (isBoardFull()) {

            //else if the board is full, then we have a tie and as a result a zero address is given to the declareGameOver function
            declareGameOver(address(0));
        } else {

            //else game continues, just change the turn to the other player
            currentPlayer = (currentPlayer == player1) ? player2 : player1;
        }
    }
    
    // this function checks if we have a winner 
    function declareWinner() internal view returns (bool) {

        // array that contains all the winning patterns
        uint8[3][8] memory winningPatterns = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
            [0, 4, 8], [2, 4, 6]             // Diagonals
        ];
        
        // foreach of the winning patterns check the board
        for (uint8 i = 0; i < 8; i++) {
            uint8[3] memory pattern = winningPatterns[i];

            // Check if the content of the winning pattern matches "SOS"
            if (
                board[pattern[0]] == Symbol.S && 
                board[pattern[1]] == Symbol.O && 
                board[pattern[2]] == Symbol.S
            ) {
                return true;
            }
        }
        return false;
    }

    
    // function that checks whether the board is full or not, to declare a tie. 
    function isBoardFull() internal view returns (bool) {
        for (uint8 i = 0; i < 9; i++) {

            // if one "-" symbol is found, then the board is not empty
            if (board[i] == Symbol.Empty) return false;
        }
        return true;
    }
    
    // declare the wiiner. If address provided is zero then we have a tie
    function declareGameOver(address winner) internal {

        // game is no longer active
        isGameActive = false;

        //populate the lastGameEndTime since the game is now over
        lastGameEndTime = block.timestamp;

        // Reset the board. This method was chosen instead of a loop, to minimize gas costs.
        board = [Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty];

        // Reset game variables
        lastMoveTime = 0;
        gameStartTime = 0;
        currentPlayer = address(0);

        // Reset state **before** sending Ether to block reentrancy
        address p1 = player1;
        address p2 = player2;
        player1 = address(0);
        player2 = address(0);
        
        // if the address is zero, then we have a tie
        if (winner == address(0)) {

            //send 0.95 ether to each player
            (bool success1, ) = payable(p1).call{value: 0.95 ether}("");
            (bool success2, ) = payable(p2).call{value: 0.95 ether}("");
            require(success1 && success2, "Transfer to players failed");
            
            //emit the tie event
            emit Tie(player1, player2);
        } else {

            //if there is a single winner send 1.8 ether
            (bool success, ) = payable(winner).call{value: 1.8 ether}("");
            require(success, "Transfer failed");

            //emit winner event
            emit Winner(winner);
        }
    }


    // this function can be called by player1 only, to cancel the game before player2 joins
    function cancelGame() external player1Only {

        //checks if player 2 joined or not. If allready joined then game cannot be canceled
        require(player2 == address(0), "Cannot cancel player 2 already joined");

        // Two minutes should pass before game can be canceled
        require(block.timestamp >= gameStartTime + 2 minutes, "Wait 2 minutes before canceling");

        // Effect: Reset game state before transferring Ether. Blocking reentrancy
        address payable refundPlayer = payable(player1);
        player1 = address(0);

        // player 1 gets back the amount paid, after resseting the state
        (bool success, ) = refundPlayer.call{value: 1 ether}("");
        require(success, "Transfer failed");
    }
    
    // function called by the owner to called funds raised by contract
    function sweepProfit(uint amount) external ownerOnly {

        //make sure enough funds remain foer the game to continue
        require(address(this).balance >= amount + 2 ether, "Cannot withdraw funds. Not enough funds for the game");
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Transfer to owner failed");
    }
    
    //this function returns the state of the board at any time
    function getGameState() external view returns (string memory) {

        // an array of bytes that is going to store the contents of the board. Board is of type symbol so it needs to be converted.
        bytes memory state = new bytes(9);

        // foreach board element
        for (uint8 i = 0; i < 9; i++) {
            if (board[i] == Symbol.Empty) {

                // Convert '-' to bytes1
                state[i] = bytes1("-"); 
            } else if (board[i] == Symbol.S) {

                // Convert 'S' to bytes1
                state[i] = bytes1("S");
            } else {

                // Convert 'O' to bytes1
                state[i] = bytes1("O");
            }
        }

        // cast bytes array to string and return it
        return string(state); 
    }

    // this function is called to cancel the game due to inactivity. Can be canceled by either the owner or the player waiting for his turn
    function tooslow() external {

        // game needs to be active
        require(isGameActive, "There is no active game at the moment");
        
        // checks whether last move, was more than one minute ago
        require(block.timestamp >= lastMoveTime + 1 minutes, "Not enough time has passed to end the game.");

        // if last move was more than five minutes ago, the owner may cancel the game
        if (block.timestamp >= lastMoveTime + 5 minutes) {

            //only the owner can declare the game a time since no move was made in the last five minutes
            require((msg.sender == owner) || (msg.sender == (currentPlayer == player1 ? player2 : player1)) , "Only the owner or the waiting player can call this after 5 minutes of inactivity");

            // game is no longer active
            isGameActive = false;

            //populate the lastGameEndTime variable with current timestamp, since game ended
            lastGameEndTime = block.timestamp;

            // Reset the board, this was to reduce gas costs
            board = [Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty];


            // Reset game variables
            lastMoveTime = 0;
            gameStartTime = 0;
            currentPlayer = address(0);

            if(msg.sender == owner){
                // Reset state **before** sending Ether to block reentrancy
                address p1 = player1;
                address p2 = player2;
                player1 = address(0);
                player2 = address(0);
                
                // send the appropriate share to its player
                (bool success1, ) = payable(p1).call{value: 0.95 ether}("");
                (bool success2, ) = payable(p2).call{value: 0.95 ether}("");
                require(success1 && success2, "Transfer failed");

                //declare the game a tie, by emitting the Tie event
                emit Tie(player1, player2);
            }
            else{
                // Reset state **before** sending Ether to block reentrancy
                address winner = msg.sender;
                player1 = address(0);
                player2 = address(0);
                // the winner of the game is the waiting player and gets 1.5 ether
                (bool success, ) = payable(winner).call{value: 1.5 ether}("");
                require(success, "Transfer failed");
                emit Winner(msg.sender);
            }
        } else {

            // if we are under the five minute threshold, then only the player who is waiting for his turn can call this function
            require(msg.sender == (currentPlayer == player1 ? player2 : player1), "Only the waiting player can call this");
            
            //delcare game is no longer active
            isGameActive = false;

            //populate the lastGameEndTime variable with current timestamp, since game ended
            lastGameEndTime = block.timestamp;

            // Reset state **before** sending Ether to block reentrancy
            address winner = msg.sender;
            player1 = address(0);
            player2 = address(0);

            // Reset the board this way to save gas
            board = [Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty, Symbol.Empty];

            // Reset game variables
            lastMoveTime = 0;
            gameStartTime = 0;
            currentPlayer = address(0);
            
            // the winner of the game is the waiting player and gets 1.5 ether
            (bool success, ) = payable(winner).call{value: 1.5 ether}("");
            require(success, "Transfer failed");
            emit Winner(msg.sender);
        }  
    }
}