# 🧠 CryptoSOS - A Decentralized SOS Game on Ethereum

CryptoSOS is a fully on-chain version of the classic SOS game, built using Solidity and deployed on the Ethereum blockchain. Two players can participate by staking 1 ETH each, playing turn-by-turn to win the pot or tie for a refund. Inactivity and owner privileges are also handled fairly and transparently.

---

## 🎮 Game Rules

- Two players join the game by sending **exactly 1 ETH** each.
- The game starts when both players have joined.
- Players take alternating turns placing either an **S** or an **O** on a **3x3 board**.
- A win is declared when the pattern **SOS** appears in any row, column, or diagonal.
- If the board is full with no winner, the game ends in a tie.
- Inactive players may forfeit the game after timeouts.

---

## ⛓️ Smart Contract Details

- **Solidity version:** `^0.8.19`
- **License:** MIT
- Designed with gas optimization, fairness, and security in mind.

---

## ⚙️ Features

### 🧑‍🤝‍🧑 Player Participation

#### `join() external payable`
- Requires the sender to send exactly **1 ETH**.
- Sets the sender as either `player1` or `player2`.
- The game begins once both players have joined.

---

### 🎯 Making Moves

#### `placeS(uint8 position)` and `placeO(uint8 position)`
- Players take turns placing an **S** or an **O** on a position between 1–9 (like a 3x3 board).
- Checks that it's the caller's turn and the position is empty.
- Emits a `Move` event upon a successful move.
- Internally calls `checkWinner()` after each move to determine if the game has been won or tied.

---

### 🏆 Declaring Winner or Tie

#### `checkWinner() internal`
- Called after every move to check for an SOS pattern in rows, columns, and diagonals.
- If a winner is found:
  - **Winner gets 1.8 ETH**.
  - Emits a `Winner` event.
- If the board is full and no winner:
  - Declares a **tie**.
  - **Each player receives 0.95 ETH**.
  - Emits a `Tie` event.

---

### 💤 Handling Inactivity

#### `tooslow() external`
- Can be called if the opponent hasn’t moved within **1 minute**.
- If **5 minutes** pass without action, the waiting player or owner can end the game.
- In that case, **the waiting player receives 1.5 ETH**, and the game resets.

---

### ⛔ Cancel Game (Before Opponent Joins)

#### `cancelGame() external`
- Can only be called by **Player 1**, and only if **Player 2 hasn't joined**.
- Refunds the 1 ETH to Player 1.

---

### 🧹 Owner Profit Sweep

#### `sweepProfit(uint amount) external`
- Only callable by the contract **owner**.
- Ensures **at least 2 ETH** remains in the contract to fund the next game.
- Used to collect extra funds (e.g., 0.1 ETH from ties).

---

### 📊 View Board State

#### `getGameState() external view returns (string)`
- Returns the current board in a 9-character string format:
  - `-` = empty
  - `S` or `O` as placed by players

Example: `"S-O--S---"`

---

### 📢 Events

- `StartGame(address player1, address player2)`
- `Move(address player, uint8 position, uint8 symbol)`
- `Winner(address winner)`
- `Tie(address player1, address player2)`

---

## 🔐 Access Control

- Functions are guarded with modifiers:
  - `onlyPlayers()`: Ensures only participants can move.
  - `onlyOwner()`: Restricts actions like `sweepProfit()` to contract owner.
  - `onlyActiveGame()`: Prevents function calls outside active game states.

---

## ✅ Security Features

- Ether is transferred **after** state changes (reentrancy protection).
- Invalid moves and unauthorized calls are strictly prevented.
- Inactivity timeouts help prevent griefing or stuck games.
- Minimum ETH balance preserved to fund future matches.

---

