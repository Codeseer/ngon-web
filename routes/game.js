var Archive = require('archive');

exports.index = function (req, res) {
	res.render('game/index', { game_src: "something" });
}

exports.new = function (req, res) {
  res.render('game/new');
}

//upload a zip
exports.upload = function (req, res) {
  req.on('end', function() {
    var reader = new Archive.Reader({
      path: req.files.gamezip.path // specify the tmp uploaded file
    });

    reader.on('file', function(file) {
      console.log(file.path, file.mtime);

      file.on('data', function(buffer) {
        console.log(buffer.toString());
        reader.nextChunk(); // get next chunk
      });

      file.on('end', function() {
        console.log('file end');
        reader.nextEntry(); // get next entry
      });

      reader.nextChunk(); // get first chunk
    });

    reader.on('error', function(err) { // archive error
      console.error(err);
    });

    reader.on('end', function() {
      console.log('archive end');
    });

    reader.open(function(info) { // open archive
      console.log(info.compression);
      reader.nextEntry();  // get first entry
    });
  });
}