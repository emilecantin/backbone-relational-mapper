define (require) ->

  Backbone = require '../../lib'

  describe 'Backbone.Collection Relations', ->

    it 'should connect', (done) ->
      Backbone.DB.connect pgConfig
      done()

    before ->
      class Player extends Backbone.RelationalModel
        fields:
          age: Backbone.Types.Integer
          name: Backbone.Types.String

      class Team extends Backbone.RelationalModel
        fields:
          name: Backbone.Types.String
          founded: Backbone.Types.Date
        relations: [
          {
            type: Backbone.HasMany
            key: 'players'
            relatedModel: Player
            reverseRelation:
              key: 'team'
          }
        ]
      Player.setup()
      Team.setup()
      @Player = Player
      @Team = Team

#    it 'should define the relations', (done) ->
#      player = new @Player
#        name: 'Bob Gratton'
#        age: 43
#      team = new @Team
#        name: 'TestTeam'
#        founded: new Date
#      player.set team: team
#      player.save()
#      player.on 'error', done
#      player.on 'sync', ->
#        #expect(JSON.stringify team.get('players').first().toJSON()).to.equal 'hello'
#        done()
