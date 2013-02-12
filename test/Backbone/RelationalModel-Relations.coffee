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

    it 'should save the association', (done) ->
      Player = @Player
      player = Player.findOrCreate
        name: 'Bob Gratton'
        age: 43
      player.off()
      team = @Team.findOrCreate
        name: 'TestTeam'
        founded: new Date
      team.off()
      team.save()
      team.on 'error', done
      team.on 'sync', ->
        expect(team.get 'id').to.equal 1
        expect(team.isNew()).to.equal false
        player.set team: team
        player.save()
        player.on 'error', done
        player.on 'sync', ->
          player2 = Player.findOrCreate id: player.get 'id'
          player2.off()
          player2.fetch()
          player2.on 'error', done
          player2.on 'sync', ->
            expect(player2.get('team').get 'id').to.equal team.get 'id'
            done()

    it 'should fetch the related models (HasOne side)', (done) ->
      Team = @Team
      player = @Player.findOrCreate id: 1
      player.off()
      player.fetch()
      player.on 'error', done
      player.on 'sync', ->
        expect(player.get('team')).to.be.an.instanceof Team
        done()

    it 'should fetch the related models (HasMany side)', (done) ->
      Player = @Player
      team = @Team.findOrCreate id: 1
      team.off()
      team.fetch()
      team.on 'error', done
      team.on 'sync', ->
        expect(team.get('players')).to.be.an.instanceof Array
        #expect(team.get('players')[0]).to.be.an.instanceof Player
        done()

    it 'should update the association', (done) ->
      Team = @Team
      Player = @Player
      team = Team.findOrCreate
        name: 'TestTeam2'
        founded: new Date
      team.off()
      team.save()
      team.on 'error', done
      team.on 'sync', ->
        expect(team.get 'id').to.equal 2
        expect(team.isNew()).to.equal false
        player = Player.findOrCreate id:1
        player.off()
        player.fetch()
        player.on 'error', done
        player.on 'sync', ->
          player.off 'sync'
          player.set team: team
          player.save()
          player.on 'error', done
          player.on 'sync', ->
            expect(player.get('team')).to.be.an.instanceof Team
            expect(player.get('team')).to.equal team
            done()

