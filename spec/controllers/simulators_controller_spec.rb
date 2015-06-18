require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe SimulatorsController do

  # This should return the minimal set of attributes required to create a valid
  # Simulator. As you add validations to Simulator, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {
      name:"simulator_A",
      parameter_definitions_attributes: [
        { key: "L", type: "Integer"},
        { key: "T", type: "Float"}
      ],
      command: "~/path_to_simulator_A"
    }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # SimulatorsController. Be sure to keep this updated too.
  def valid_session
    {}
  end

  describe "GET index" do

    it "assigns all simulators as @simulators" do
      simulator = Simulator.create! valid_attributes
      get :index, {}, valid_session
      response.should be_success
      assigns(:simulators).should eq([simulator])
    end

    it "@simulators are sorted by the position" do
      simulators = FactoryGirl.create_list(:simulator, 3)
      simulators.first.update_attribute(:position, 2)
      simulators.last.update_attribute(:position, 0)
      sorted = simulators.sort_by {|sim| sim.position }
      get :index, {}, valid_session
      assigns(:simulators).should eq sorted
    end
  end

  describe "GET show" do

    before(:each) do
      @simulator = FactoryGirl.create(:simulator,
                                      parameter_sets_count: 5, runs_count: 0,
                                      analyzers_count: 3, run_analysis: false,
                                      parameter_set_queries_count: 5
                                      )
    end

    it "assigns the requested simulator as @simulator" do
      get :show, {id: @simulator.to_param}, valid_session
      response.should be_success
      assigns(:simulator).should eq(@simulator)
      assigns(:analyzers).should eq(@simulator.analyzers)
      assigns(:query_id).should be_nil
      expect(assigns(:query_list).size).to eq 5
    end
  end

  describe "GET new" do
    it "assigns a new simulator as @simulator" do
      get :new, {}, valid_session
      assigns(:simulator).should be_a_new(Simulator)
    end

    it "@duplicating_simulator is nil" do
      get :new, {}, valid_session
      assigns(:duplicating_simulator).should be_nil
    end
  end

  describe "GET duplicate" do

    before(:each) do
      @simulator = FactoryGirl.create(:simulator, parameter_sets_count: 0, analyzers_count: 2)
    end

    it "assigns a new simulator as @simulator" do
      get :duplicate, {id: @simulator}, valid_session
      assigns(:simulator).should be_a_new(Simulator)
      assigns(:simulator).name.should eq @simulator.name
      assigns(:simulator).command.should eq @simulator.command
      keys = @simulator.parameter_definitions.map(&:key)
      assigns(:simulator).parameter_definitions.map(&:key).should eq keys
    end

    it "assigns the original simulator to @duplicating_simulator" do
      get :duplicate, {id: @simulator}, valid_session
      assigns(:duplicating_simulator).should eq @simulator
    end

    it "assigns analyzers of the original simulator to @copied_analyzers" do
      get :duplicate, {id: @simulator}, valid_session
      assigns(:copied_analyzers).should =~ @simulator.analyzers
    end
  end

  describe "GET edit" do
    it "assigns the requested simulator as @simulator" do
      simulator = Simulator.create! valid_attributes
      get :edit, {:id => simulator.to_param}, valid_session
      assigns(:simulator).should eq(simulator)
    end
  end

  describe "POST create" do
    describe "with valid params" do

      before(:each) do
        host = FactoryGirl.create(:host)
        definitions = [
          {key: "param1", type: "Integer"},
          {key: "param2", type: "Float"}
        ]
        simulator = {
          name: "simulatorA", command: "echo", support_input_json: "0",
          support_mpi: "0", support_omp: "1",
          parameter_definitions_attributes: definitions,
          executable_on_ids: [host.id.to_s]
        }
        @valid_post_parameter = {simulator: simulator}
      end

      it "creates a new Simulator" do
        expect {
          post :create, @valid_post_parameter, valid_session
        }.to change(Simulator, :count).by(1)
      end

      it "assigns attributes of newly created Simulator" do
        post :create, @valid_post_parameter, valid_session
        sim = Simulator.last
        sim.name.should eq "simulatorA"
        sim.command.should eq "echo"
        sim.support_input_json.should be_falsey
        sim.parameter_definition_for("param1").type.should eq "Integer"
        sim.parameter_definition_for("param2").type.should eq "Float"
        sim.support_mpi.should be_falsey
        sim.support_omp.should be_truthy
      end

      it "assigns a newly created simulator as @simulator" do
        post :create, @valid_post_parameter, valid_session
        assigns(:simulator).should be_a(Simulator)
        assigns(:simulator).should be_persisted
      end

      it "redirects to the created simulator" do
        post :create, @valid_post_parameter, valid_session
        response.should redirect_to(Simulator.last)
      end
    end

    describe "when duplicating a simulator" do

      before(:each) do
        @sim = FactoryGirl.create(:simulator, parameter_sets_count: 0, analyzers_count: 2)
        definitions = @sim.parameter_definitions.map {|pd| {key: pd.key, type: pd.type} }
        simulator = {
          name: "duplicated", command: @sim.command, support_input_json: "0",
          support_mpi: "0", support_omp: "1",
          parameter_definitions_attributes: definitions
        }
        @valid_post_parameter = {
          simulator: simulator,
          duplicating_simulator: @sim.id.to_s, copied_analyzers: @sim.analyzers.map(&:id).map(&:to_s)
        }
      end

      it "creates a new Simulator" do
        expect {
          post :create, @valid_post_parameter, valid_session
        }.to change(Simulator, :count).by(1)
      end

      it "creates a new Analyzer" do
        expect {
          post :create, @valid_post_parameter, valid_session
        }.to change(Analyzer, :count).by(2)
      end

      it "does not create a new analyzer when copied_analyzers is nil" do
        @valid_post_parameter[:copied_analyzers] = nil
        expect {
          post :create, @valid_post_parameter, valid_session
        }.to_not change(Analyzer, :count)
      end

      it "does not create a new Analyzer when simulator is not created" do
        @valid_post_parameter[:simulator][:name] = @sim.name
        expect {
          post :create, @valid_post_parameter, valid_session
        }.to_not change(Analyzer, :count)
      end

      it "assigns @duplicating_simulator and @copied_analyzers when invalid param is given" do
        @valid_post_parameter[:simulator][:name] = @sim.name
        # remove one in order to verify the checkboxes are maintained when error is happened
        @valid_post_parameter[:copied_analyzers].shift

        post :create, @valid_post_parameter, valid_session
        assigns(:duplicating_simulator).should eq @sim
        expect(assigns(:copied_analyzers).size).to eq 1
      end
    end

    describe "with invalid params" do

      it "assigns a newly created but unsaved simulator as @simulator" do
        expect {
          post :create, {simulator: {}}, valid_session
          assigns(:simulator).should be_a_new(Simulator)
        }.to_not change(Simulator, :count)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        post :create, {simulator: {}}, valid_session
        response.should render_template("new")
      end
    end

    describe "with no permitted params" do

      it "create new simulator but no permitted params are not saved" do
        invalid_params = valid_attributes.update(position: 100)
                                          .update(default_host_parameters: {"host_id"=>{"param1"=>123}})
                                          .update(default_mpi_procs: {"host_id"=>12345})
                                          .update(default_omp_threads: {"host_id"=>54321})
                                          .update(invalid: 1)
        expect {
          post :create, {simulator: invalid_params, invalid: 1}, valid_session
        }.to change {Simulator.count}.by(1)
        sim = Simulator.last
        expect(sim.position).not_to eq 100
        expect(sim.default_host_parameters).not_to include({"host_id"=>{"param1"=>123}})
        expect(sim.default_mpi_procs).not_to include({"host_id"=>12345})
        expect(sim.default_omp_threads).not_to include({"host_id"=>54321})
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do

      before(:each) do
        definitions = [
          {key: "param1", type: "Integer"},
          {key: "param2", type: "Float"}
        ]
        @valid_post_parameter = {
          name: "simulatorA", command: "echo", support_input_json: "0",
          support_mpi: "0", support_omp: "1",
          parameter_definitions_attributes: definitions
        }
      end

      it "updates the requested simulator" do
        simulator = Simulator.create! valid_attributes
        Simulator.any_instance.should_receive(:update_attributes).with({'description' => 'yyy zzz'})
        put :update, {:id => simulator.to_param, :simulator => {'description' => 'yyy zzz'}}, valid_session
      end

      it "assigns the requested simulator as @simulator" do
        simulator = Simulator.create! valid_attributes
        put :update, {:id => simulator.to_param, :simulator => @valid_post_parameter}, valid_session
        expect(assigns(:simulator).id).to eq simulator.id
        expect(assigns(:simulator).command).to eq "echo"
        expect(assigns(:simulator).support_input_json).to be_falsey
        expect(assigns(:simulator).support_mpi).to be_falsey
        expect(assigns(:simulator).support_omp).to be_truthy
      end

      it "redirects to the simulator" do
        simulator = Simulator.create! valid_attributes
        put :update, {:id => simulator.to_param, :simulator => @valid_post_parameter}, valid_session
        response.should redirect_to(simulator)
      end
    end

    describe "with invalid params" do
      it "assigns the simulator as @simulator" do
        simulator = Simulator.create! valid_attributes
        Simulator.any_instance.stub(:save).and_return(false)
        put :update, {:id => simulator.to_param, :simulator => {}}, valid_session
        assigns(:simulator).should eq(simulator)
      end

      it "re-renders the 'edit' template" do
        simulator = Simulator.create! valid_attributes
        Simulator.any_instance.stub(:save).and_return(false)
        put :update, {:id => simulator.to_param, :simulator => {}}, valid_session
        response.should render_template("edit")
      end
    end

    describe "with no permitted params" do

      before(:each) do
        definitions = [
          {key: "param1", type: "Integer"},
          {key: "param2", type: "Float"}
        ]
        @valid_post_parameter = {
          name: "simulatorA", command: "echo", support_input_json: "0",
          support_mpi: "0", support_omp: "1",
          parameter_definitions_attributes: definitions
        }
      end

      it "update new simulator but no permitted params are not saved" do
        simulator = Simulator.create! valid_attributes
        invalid_params = @valid_post_parameter.update(description: "yyy zzz")
                                              .update(position: 100)
                                              .update(default_host_parameters: {"host_id"=>{"param1"=>123}})
                                              .update(default_mpi_procs: {"host_id"=>12345})
                                              .update(default_omp_threads: {"host_id"=>54321})
                                              .update(invalid: 1)
        post :update, {id: simulator.to_param, simulator: invalid_params, invalid: 1}, valid_session
        expect(assigns(:simulator).description).to eq "yyy zzz"
        expect(assigns(:simulator).position).not_to eq 100
        expect(assigns(:simulator).default_host_parameters).not_to include({"host_id"=>{"param1"=>123}})
        expect(assigns(:simulator).default_mpi_procs).not_to include({"host_id"=>12345})
        expect(assigns(:simulator).default_omp_threads).not_to include({"host_id"=>54321})
      end
    end
  end

  describe "DELETE destroy" do

    before(:each) do
      @sim = FactoryGirl.create(:simulator, parameter_sets_count: 0)
    end

    it "destroys the requested simulator" do
      expect {
        delete :destroy, {id: @sim.to_param}, valid_session
      }.to change(Simulator, :count).by(-1)
    end

    it "redirects to the simulators list" do
      delete :destroy, {id: @sim.to_param}, valid_session
      response.should redirect_to(simulators_url)
    end
  end

  describe "POST _make_query" do
    before(:each) do
      @simulator = FactoryGirl.create(:simulator,
                                      parameter_sets_count: 1, runs_count: 0,
                                      analyzers_count: 3, run_analysis: false,
                                      parameter_set_queries_count: 1
                                      )
    end

    context "with valid params" do

      before(:each) do
        params = [{"param"=>"T", "matcher"=>"gte", "value"=>"4.0", "logic"=>"and"},
                  {"param"=>"L", "matcher"=>"eq", "value"=>"2", "logic"=>"and"}
                 ]
        @valid_post_parameter = {:id => @simulator.to_param, "query" => params, query_id: @simulator.parameter_set_queries.first.id.to_s}
      end

      it "creates a new ParameterSetQuery" do
        expect {
          post :_make_query, @valid_post_parameter, valid_session
        }.to change(ParameterSetQuery, :count).by(1)
      end

      it "assigns a newly created parameter_set_query of @simulator" do
        post :_make_query, @valid_post_parameter, valid_session
        assigns(:new_query).should be_a(ParameterSetQuery)
        assigns(:new_query).query.should eq({"T" =>{"gte"=>4.0}, "L" =>{"eq"=>2}})
        assigns(:new_query).should be_persisted
      end

      it "redirects to show with the created parameter_set_query" do
        post :_make_query, @valid_post_parameter, valid_session
        response.should redirect_to( simulator_path(@simulator, query_id: ParameterSetQuery.last.to_param) )
        assigns(:query_id).should == ParameterSetQuery.last.id.to_s
      end

      context "and with delete option" do
        it "delete the last parameter_set_query of @simulator" do
          expect {
            post :_make_query, {:id => @simulator.to_param, delete_query: "xxx", query_id: @simulator.parameter_set_queries.first.id.to_s}, valid_session
          }.to change(ParameterSetQuery, :count).by(-1)
        end
      end
    end

    context "with invalid params" do

      it "assigns a newly created but unsaved paramater_set_query of @simulator" do
        expect {
          post :_make_query, {:id => @simulator.to_param, params: {}}, valid_session
          assigns(:new_query).should be_a_new(ParameterSetQuery)
        }.to_not change(ParameterSetQuery, :count)
      end

      it "redirect to show with nonmodified query_id" do
        post :_make_query, {:id => @simulator.to_param, params: {}, query_id: ""}, valid_session
        response.should redirect_to( simulator_path(@simulator, query_id: "") )
      end
    end
  end

  describe "GET _parameters_list" do
    before(:each) do
      @simulator = FactoryGirl.create(:simulator,
                                      parameter_sets_count: 30, runs_count: 0,
                                      analyzers_count: 3, run_analysis: false,
                                      parameter_set_queries_count: 5
                                      )
      get :_parameters_list, {id: @simulator.to_param, draw: 1, start: 0, length:25 , "order" => {"0" => {"column" => "0", "dir" => "asc"}}}, :format => :json
      @parsed_body = JSON.parse(response.body)
    end

    it "return json format" do
      response.header['Content-Type'].should include 'application/json'
      expect(@parsed_body["recordsTotal"]).to eq 30
      expect(@parsed_body["recordsFiltered"]).to eq 30
    end

    it "paginates the list of parameters" do
      expect(@parsed_body["data"].size).to eq 25
    end

    context "when 'query_id' parameter is given" do

      before(:each) do
        @simulator = FactoryGirl.create(:simulator, parameter_sets_count: 0)
        10.times do |i|
          FactoryGirl.create(:parameter_set,
                             simulator: @simulator,
                             runs_count: 0,
                             v: {"L" => i, "T" => i*2.0}
                             )
        end
        @query = FactoryGirl.create(:parameter_set_query,
                                    simulator: @simulator,
                                    query: {"L" => {"gte" => 5}})

        # columns ["id", "progress_rate_cache", "id", "updated_at"] + @param_keys.map {|key| "v.#{key}"} + ["id"]
        get :_parameters_list, {id: @simulator.to_param, draw: 1, start: 0, length:25 , "order" => {"0" => {"column" => "4", "dir" => "desc"}}, query_id: @query.id.to_s}, :format => :json
        @parsed_body = JSON.parse(response.body)
      end

      it "show the list of filtered ParameterSets" do
        expect(@parsed_body["data"].size).to eq 5
        @parsed_body["data"].each do |ps|
          expect(ps[4].to_i).to be >= 5 #ps[3].to_i is qeual to v.L(ps[img, id, id, updated_at, [keys]])
        end
        expect(@parsed_body["data"].first[4].to_i).to eq @query.parameter_sets.max("v.L")
      end
    end
  end

  describe "GET _progress" do
    before(:each) do
      @simulator = FactoryGirl.create(:simulator,
                                      parameter_sets_count: 30, runs_count: 3
                                      )
      get :_progress, {id: @simulator.to_param, column_parameter: 'L', row_parameter: 'T'}, :format => :json
      @parsed_body = JSON.parse(response.body)
    end

    it "return json format" do
      response.should be_success
      response.header['Content-Type'].should include 'application/json'
      @parsed_body["parameters"].should eq ["L", "T"]
      @parsed_body["parameter_values"].should be_a(Array)
      @parsed_body["num_runs"].should be_a(Array)
    end
  end

  describe "POST _sort" do

    before(:each) do
      FactoryGirl.create_list(:simulator, 3)
    end

    it "updates position of the simulators" do
      simulators = Simulator.asc(:position).to_a
      expect {
        post :_sort, {simulator: simulators.reverse }
        response.should be_success
      }.to change { simulators.first.reload.position }.from(0).to(2)
    end
  end

  describe "GET _host_parameters_field" do

    before(:each) do
      @host = FactoryGirl.create(:host_with_parameters)
      @sim = FactoryGirl.create(:simulator, parameter_sets_count: 0)
      @sim.executable_on.push(@host)
    end

    it "returns http success" do
      valid_param = {id: @sim.to_param, host_id: @host.to_param}
      get :_host_parameters_field, valid_param, valid_session
      response.should be_success
    end

    it "returns http success if host_id is not found" do
      param = {id: @sim.to_param, host_id: "manual"}
      get :_host_parameters_field, param, valid_session
      response.should be_success
    end
  end

  describe "GET _default_mpi_omp" do

    before(:each) do
      @host = FactoryGirl.create(:host_with_parameters)
      @sim = FactoryGirl.create(:simulator,
                                parameter_sets_count: 0, support_mpi: true, support_omp: true)
      @sim.executable_on.push(@host)
    end

    it "returns http success" do
      valid_param = {id: @sim.to_param, host_id: @host.to_param}
      get :_default_mpi_omp, valid_param, valid_session
      response.should be_success
    end

    context "when default_mpi_procs and/or defualt_omp_threads are set" do

      before(:each) do
        @sim.update_attribute(:default_mpi_procs, {@host.id.to_s => 8})
        @sim.update_attribute(:default_omp_threads, {@host.id.to_s => 4})
      end

      it "returns mpi_procs and omp_threads in json" do
        valid_param = {id: @sim.to_param, host_id: @host.to_param}
        get :_default_mpi_omp, valid_param, valid_session
        response.header['Content-Type'].should include 'application/json'
        parsed = JSON.parse(response.body)
        parsed.should eq ({'mpi_procs' => 8, 'omp_threads' => 4})
      end
    end

    context "when default_mpi_procs or default_omp_threads is not set" do

      before(:each) do
        @sim.update_attribute(:default_mpi_procs, {})
        @sim.update_attribute(:default_omp_threads, {})
      end

      it "returns mpi_procs and omp_threads in json" do
        valid_param = {id: @sim.to_param, host_id: @host.to_param}
        get :_default_mpi_omp, valid_param, valid_session
        response.header['Content-Type'].should include 'application/json'
        parsed = JSON.parse(response.body)
        parsed.should eq ({'mpi_procs' => 1, 'omp_threads' => 1})
      end
    end
  end
end
