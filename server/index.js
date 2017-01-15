var http = require('http');
var express = require('express');
var bodyParser = require('body-parser')
var app = express();
var server = http.createServer(app);
app.use( bodyParser.json() );

server.listen(8900)
var io = require('socket.io')(server)

//save this roomId on client too so we can use in in our connect: var socket = io('/my-room-id');
app.post('/createRoom', function(req, res) {
    var roomId = req.body.roomId;
    var words = req.body.words;
    res.send("created room "+roomId);
    new Game(roomId, words);
});

function Player(name, nsp) {
    var self = this
    this.nsp = nsp
    this.name = name
	this.isSleeping = false;
    this.game = {}
}

Player.prototype.joinGame = function(game) {
    this.game = game
}

function Game(roomId, words) {
    this.roomId = roomId;
    this.words = words;
    this.players = [];
    this.io = io;
    this.started = false
    this.addHandlers()
    console.log("created game with roomId "+this.roomId);
}

Game.prototype.addHandlers = function() {
    var game = this;
    var nsp = this.io.of(this.roomId);
    nsp.on('connection', function(socket){
        console.log('connection made to room '+game.roomId);
        var playerName = socket.handshake.query.name;
		var player = game.players.find(x => x.name == playerName);
		if (!player) {
     	   game.addPlayer(new Player(playerName, nsp));
		} else {
			player.isSleeping = false;
			if (game.over) {
				game.announceWin(game.overData.winningPlayerName, game.overData.winningAnswers);
			}
			console.log('wake by ' + playerName);
		}
        socket.on('win', function(name, answers) {
          game.announceWin(name, answers);
        })
		socket.on('sleeping', function() {
			var player = game.players.find(x => x.name == playerName);
			player.isSleeping = true;
		})
        socket.on('disconnect', function() {
			var player = game.players.find(x => x.name == playerName);
			if (!player.isSleeping) {
     		     console.log('disconnect by '+ playerName);
     		     game.removePlayer(playerName);
			} else {
				console.log('sleep by ' + playerName);
			}
        })
    });
}

Game.prototype.addPlayer = function(player) {
    console.log("adding player")
    this.players.push(player);
    player["game"] = this;
    console.log(this.words)
    player.nsp.emit("playerJoined", player["name"], this.words);
}

Game.prototype.removePlayer = function(name) {
  console.log("removing player");
  var p = null;
  var index = null;
  for(var i = 0; i < this.players.length; i++) {
    console.log(this.players[i].name);
    if (this.players[i].name == name) {
      p = this.players[i];
      index = i;
      break;
    }
  }
  if (p != null) {
    p.nsp.emit("playerLeft", name);
    this.players.splice(index, 1);
  }
  //if this was the last player to leave, and the game is won, end game
  if (this.players.length == 0 && this.over) {
    gameOver(this.roomId);
  }
}

Game.prototype.announceWin = function(playerName, answers) {
    console.log("announcing winner");
    console.log(playerName)
    for(var i = 0; i < this.players.length; i++) {
        this.players[i].nsp.emit("win", playerName, answers);
    }
    this.over = true;
	this.overData = { winningPlayerName: playerName, winningAnswers: answers }
}

function gameOver(roomId) {
  var nsp = io.of(roomId);
  const connectedNameSpaceSockets = Object.keys(nsp.connected); // Get Object with Connected SocketIds as properties
  for (var i = 0; i < connectedNameSpaceSockets.length; i++) {
      connectedNameSpaceSockets[i].disconnect(); // Disconnect Each socket
  }
  nsp.removeAllListeners(); // Remove all Listeners for the event emitter
  delete io.nsps['/' + roomId]; // Remove from the server namespaces
}
