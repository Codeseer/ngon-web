Game = require '../models/game'

exports.index = (req, res) ->
  Game.find().exec (err,games) ->
    res.render 'index',
      title: 'N-Gon Games LLC'
      games: games