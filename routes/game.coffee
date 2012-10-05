spawn = require('child_process').spawn
fs = require 'fs' 
cloudfiles = require 'cloudfiles'
Game = require '../models/game'

config =
  auth:
    username: 'codeseer',
    apiKey: '3ba10710c3c62939734df5f9c8f81c16'

client = cloudfiles.createClient config

exports.index = (req, res) ->
  Game.findOne(name: req.params.name).exec (err, game) ->
    if(!game)
      res.send 404
    else
      res.render 'game/index', game: game

exports.new = (req, res) ->
  res.render 'game/new'

#upload a zip
exports.upload = (req, res) ->
  unzip = spawn 'unzip', [req.files.game_zip.path, '-d', req.files.game_zip.path+'_unzip']
  unzip.on 'exit', (code) ->
    if code == 0
      #add the thumbnail and the banner to the unzip folder
      mvPics = spawn 'mv', [req.files.game_thumbnail.path, req.files.game_zip.path+'_unzip/thumbnail.png']
      mvPics.on 'exit', (code) ->
        console.log 'moved'+req.files.game_thumbnail.filename
        mvPics = spawn 'mv', [req.files.game_banner.path, req.files.game_zip.path+'_unzip/banner.png']
        mvPics.on 'exit', (code) ->
          console.log 'moved'+req.files.game_banner.filename
          if code == 0
            walk req.files.game_zip.path + '_unzip', (err, files) ->
              #create the container
              client.setAuth () ->                
                newContainer = new cloudfiles.Container client, 
                  name: req.body.name
                  cdnEnabled: true
                client.createContainer newContainer, (err, container) ->
                  if err
                    res.send 'There was an error uploading the game.'
                  else
                    files.forEach (file) ->
                      uploadFile = ()->
                        remoteFile = file.replace req.files.game_zip.path + '_unzip/', ''
                        container.addFile {remote: remoteFile, local: file}, (err, uploaded) ->
                          console.log remoteFile + ' uploaded'
                      #compress if it is a png image
                      if file.endsWith('.png')
                        outFile = file.replace '.png', ''
                        outFile += '_compressed.png'
                        pngcrush = spawn 'pngcrush', [file,outFile]
                        pngcrush.on 'exit', (code) ->
                          if code != 0
                            console.log 'exit code '+code+' could not compress file ' + file 
                            uploadFile()
                          else
                            console.log 'Successfuly compressed '+file
                            mvFiles = spawn 'mv', [outFile,file]
                            mvFiles.on 'exit', (code) ->
                              if code != 0
                                console.log 'exit code '+code+' could not overwrite non compressed file'
                                uploadFile()
                              else
                                uploadFile()                        
                      else
                        uploadFile()
                  #Save the game settings to the database
                  newGame = new Game
                    cdnUrl: container.cdnUri
                    name: req.body.name
                    description: req.body.description
                  newGame.save (err) ->
                    if(err)
                      res.statusCode = 500
                      res.send err.toString()
                    else
                      res.send container.cdnUri
    else
      res.send 'Unable to unzip your file.'

walk = (dir, done) ->
  results = []; 
  fs.readdir dir, (err, list) ->
    if err
      return done err
    pending = list.length;
    if !pending
      return done null, results
    list.forEach (file) ->
      file = dir + '/' + file
      fs.stat file, (err, stat) ->
        if stat && stat.isDirectory()
          walk file, (err, res) ->
            results = results.concat res
            if !--pending
              done null, results
        else
          results.push file
          if !--pending 
            done null, results