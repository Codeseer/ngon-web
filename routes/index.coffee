exports.index = (req, res) ->
  res.render 'index',
    title: 'N-Gon Games LLC'
    games: [
        title: 'HueBrix'
        description: 'A really fun puzzle game'
        cdnUrl: ''          
        ,
          title: 'HueBrix2'
          description: 'Another really fun puzzle game everyone loves to play and stuff you know'
          cdnUrl: ''
      ]