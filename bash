npm init -y
npm install express socket.io
const express = require("express");
const http = require("http");
const { Server } = require("socket.io");

const app = express();
const server = http.createServer(app);
const io = new Server(server);

const port = 3000;

// 保存棋局資料
let board = Array(15).fill(null).map(() => Array(15).fill(null));
let currentPlayer = "black";

io.on("connection", (socket) => {
    console.log("一位玩家已連接");

    // 發送當前棋盤狀態
    socket.emit("init", { board, currentPlayer });

    // 接收下棋動作
    socket.on("placePiece", ({ row, col }) => {
        if (board[row][col] === null) {
            board[row][col] = currentPlayer;

            // 通知所有玩家棋局更新
            io.emit("updateBoard", { row, col, player: currentPlayer });

            // 切換玩家
            currentPlayer = currentPlayer === "black" ? "white" : "black";

            io.emit("switchPlayer", currentPlayer);
        }
    });

    // 重置遊戲
    socket.on("reset", () => {
        board = Array(15).fill(null).map(() => Array(15).fill(null));
        currentPlayer = "black";
        io.emit("resetGame", { board, currentPlayer });
    });

    socket.on("disconnect", () => {
        console.log("一位玩家已斷開連接");
    });
});

// 提供靜態檔案 (HTML)
app.use(express.static("public"));

server.listen(port, () => {
    console.log(`伺服器運行於 http://localhost:${port}`);
});
<!DOCTYPE html>
<html lang="zh">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>五子棋 - 線上對戰</title>
    <style>
        body {
            text-align: center;
            font-family: Arial, sans-serif;
        }
        #board {
            display: grid;
            grid-template-columns: repeat(15, 30px);
            grid-template-rows: repeat(15, 30px);
            margin: 0 auto;
            background-color: #d9a066;
        }
        .cell {
            border: 1px solid #888;
            position: relative;
        }
        .cell.taken::before {
            content: '';
            width: 20px;
            height: 20px;
            border-radius: 50%;
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
        }
        .cell.black::before { background-color: black; }
        .cell.white::before { background-color: white; border: 1px solid #888; }
    </style>
</head>
<body>
    <h1>五子棋 - 線上對戰</h1>
    <div id="status">等待連接...</div>
    <div id="board"></div>
    <button onclick="resetGame()">重新開始</button>

    <script src="/socket.io/socket.io.js"></script>
    <script>
        const socket = io();
        const boardElement = document.getElementById("board");
        const statusElement = document.getElementById("status");

        let board = [];
        let currentPlayer = "black";
        let myTurn = false;

        // 初始化棋盤
        function createBoard() {
            boardElement.innerHTML = "";
            for (let i = 0; i < 15; i++) {
                for (let j = 0; j < 15; j++) {
                    const cell = document.createElement("div");
                    cell.classList.add("cell");
                    cell.dataset.row = i;
                    cell.dataset.col = j;
                    boardElement.appendChild(cell);
                }
            }
        }

        // 下棋動作
        boardElement.addEventListener("click", (e) => {
            if (!myTurn) return;

            const cell = e.target;
            const row = cell.dataset.row;
            const col = cell.dataset.col;

            if (board[row][col] === null) {
                socket.emit("placePiece", { row, col });
                myTurn = false;
            }
        });

        // 接收伺服器初始化資料
        socket.on("init", (data) => {
            board = data.board;
            currentPlayer = data.currentPlayer;
            createBoard();
            renderBoard();
            updateStatus();
        });

        // 更新棋盤
        socket.on("updateBoard", ({ row, col, player }) => {
            board[row][col] = player;
            renderBoard();
        });

        socket.on("switchPlayer", (player) => {
            currentPlayer = player;
            updateStatus();
        });

        socket.on("resetGame", (data) => {
            board = data.board;
            currentPlayer = data.currentPlayer;
            renderBoard();
            updateStatus();
        });

        function renderBoard() {
            document.querySelectorAll(".cell").forEach((cell) => {
                const row = cell.dataset.row;
                const col = cell.dataset.col;
                cell.className = "cell"; // 清除樣式
                if (board[row][col]) {
                    cell.classList.add("taken", board[row][col]);
                }
            });
        }

        function updateStatus() {
            statusElement.textContent = `輪到玩家：${currentPlayer === "black" ? "黑棋" : "白棋"}`;
            myTurn = currentPlayer === "black"; // 假設一開始自己是黑棋
        }

        function resetGame() {
            socket.emit("reset");
        }
    </script>
</body>
</html>
node server.js

