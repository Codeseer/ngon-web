mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

Game = new Schema
  cdnUrl:
    type: String
    required: true
  gameName: 
    type: String
    required: true
  description:
    type: String
  genre:
    #refrece to a genre model
    type: ObjectId
  views:
    default:0

module.exports = mongoose.model 'game', Game