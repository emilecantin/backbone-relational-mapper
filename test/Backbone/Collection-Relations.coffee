define (require) ->

  Backbone = require '../../lib'

  describe 'Backbone.Collection Relations', ->

    it 'should connect', (done) ->
      Backbone.DB.logger = (string) -> console.log string
      Backbone.DB.connect pgConfig
      done()

    before ->
      class Employee extends Backbone.RelationalModel
        fields:
          id: Backbone.Types.Primary
          age: Backbone.Types.Integer
          name: Backbone.Types.String

      class Company extends Backbone.RelationalModel
        fields:
          id: Backbone.Types.Primary
          name: Backbone.Types.String
          founded: Backbone.Types.Date
        relations: [
          {
            type: Backbone.HasMany
            key: 'employees'
            relatedModel: Employee
            reverseRelation:
              key: 'company'
          }
        ]
      Employee.setup()
      Company.setup()
      @Employee = Employee
      @Company = Company

      class @Companies extends Backbone.Collection
        model: Company
      class @Employees extends Backbone.Collection
        model: Employee

    it 'should fetch the related models (HasOne)', (done) ->
      Company = @Company
      employees = new @Employees
      employees.fetch
        db_params:
          include_relations: true
      employees.on 'error', done
      employees.on 'sync', ->
        expect(employees.length).to.equal 7
        expect(employees.first().get 'id').to.equal 1
        expect(employees.first().get 'company').to.be.an.instanceof Company
        expect(employees.first().get('company').get 'name').to.equal "Company1"
        done()

    it 'should fetch the related models (HasMany)', (done) ->
      Employee = @Employee
      companies = new @Companies
      companies.fetch
        db_params:
          include_relations: true
      companies.on 'error', done
      companies.on 'sync', ->
        expect(companies.length).to.equal 2
        expect(companies.first().get 'id').to.equal 1
        expect(companies.first().get 'employees').to.be.an.instanceof Backbone.Collection
        expect(companies.first().get('employees').length).to.equal 4
        expect(companies.first().get('employees').first()).to.be.an.instanceof Employee
        done()

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
