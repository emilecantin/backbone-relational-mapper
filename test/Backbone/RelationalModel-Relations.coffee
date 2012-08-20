define (require) ->

  Backbone = require '../../lib'

  describe 'Backbone.Collection Relations', ->

    it 'should connect', (done) ->
      Backbone.DB.connect pgConfig
      done()

    before ->
      class Player extends Backbone.RelationalModel
        fields:
          id: Backbone.Types.Primary
          age: Backbone.Types.Integer
          name: Backbone.Types.String

      class Team extends Backbone.RelationalModel
        fields:
          id: Backbone.Types.Primary
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

    it 'should save the related models', (done) ->
      Player = @Player
      player = new Player
        name: 'Bob Gratton'
        age: 43
      team = new @Team
        name: 'TestTeam'
        founded: new Date
      team.save()
      team.on 'error', done
      team.on 'sync', ->
        expect(team.get 'id').to.equal 1
        expect(team.isNew()).to.equal false
        player.set team: team
        player.save()
        player.on 'error', done
        player.on 'sync', ->
          player2 = new Player id: player.get 'id'
          player2.fetch()
          player2.on 'error', done
          player2.on 'sync', ->
            expect(player2.get('team').get 'id').to.equal team.get 'id'
            done()
