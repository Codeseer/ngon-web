spawn = require('child_process').spawn
fs = require 'fs' 
cloudfiles = require 'cloudfiles'

config =
  auth:
    username: 'codeseer',
    apiKey: '3ba10710c3c62939734df5f9c8f81c16'

client = cloudfiles.createClient config

exports.index = (req, res) ->
  res.render 'game/index', game_src: "something"

exports.new = (req, res) ->
  res.render 'game/new'

#upload a zip
exports.upload = (req, res) ->
  unzip = spawn 'unzip', [req.files.game_zip.path, '-d', req.files.game_zip.path+'_unzip']
  unzip.on 'exit', (code) ->
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
                  uploadZipFile = ()->
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
                        uploadZipFile()
                    else
                      console.log 'Successfuly compressed '+file
                      mvFiles = spawn 'mv', [outFile,file]
                      mvFiles.on 'exit', (code) ->
                        if code != 0
                          console.log 'exit code '+code+' could not overwrite non compressed file'
                            uploadZipFile()
                        else
                            uploadZipFile()                        
                else
                    uploadZipFile()
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