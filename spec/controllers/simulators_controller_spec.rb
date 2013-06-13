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
      parameter_definitions: {
        "L" => {"type" => "Integer"},
        "T" => {"type" => "Float"}
      },
      command: "~/path_to_simulator_A",
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
      assigns(:query_list).should have(5).items
    end
  end

  describe "GET new" do
    it "assigns a new simulator as @simulator" do
      get :new, {}, valid_session
      assigns(:simulator).should be_a_new(Simulator)
    end
  end

  # describe "GET edit" do
  #   it "assigns the requested simulator as @simulator" do
  #     simulator = Simulator.create! valid_attributes
  #     get :edit, {:id => simulator.to_param}, valid_session
  #     assigns(:simulator).should eq(simulator)
  #   end
  # end

  describe "POST create" do
    describe "with valid params" do

      before(:each) do
        definitions = [
          {"name" => "param1", "type" => "Integer"},
          {"name" => "param2", "type" => "Float"}
        ]
        simulator = {name: "simulatorA", command: "echo", support_input_json: "0"}
        @valid_post_parameter = {simulator: simulator, definitions: definitions}
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
        sim.support_input_json.should be_false
        sim.parameter_definitions["param1"]["type"].should eq "Integer"
        sim.parameter_definitions["param2"]["type"].should eq "Float"
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
  end

  # describe "PUT update" do
  #   describe "with valid params" do
  #     it "updates the requested simulator" do
  #       simulator = Simulator.create! valid_attributes
  #       # Assuming there are no other simulators in the database, this
  #       # specifies that the Simulator created on the previous line
  #       # receives the :update_attributes message with whatever params are
  #       # submitted in the request.
  #       Simulator.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
  #       put :update, {:id => simulator.to_param, :simulator => {'these' => 'params'}}, valid_session
  #     end

  #     it "assigns the requested simulator as @simulator" do
  #       simulator = Simulator.create! valid_attributes
  #       put :update, {:id => simulator.to_param, :simulator => valid_attributes}, valid_session
  #       assigns(:simulator).should eq(simulator)
  #     end

  #     it "redirects to the simulator" do
  #       simulator = Simulator.create! valid_attributes
  #       put :update, {:id => simulator.to_param, :simulator => valid_attributes}, valid_session
  #       response.should redirect_to(simulator)
  #     end
  #   end

  #   describe "with invalid params" do
  #     it "assigns the simulator as @simulator" do
  #       simulator = Simulator.create! valid_attributes
  #       # Trigger the behavior that occurs when invalid params are submitted
  #       Simulator.any_instance.stub(:save).and_return(false)
  #       put :update, {:id => simulator.to_param, :simulator => {}}, valid_session
  #       assigns(:simulator).should eq(simulator)
  #     end

  #     it "re-renders the 'edit' template" do
  #       simulator = Simulator.create! valid_attributes
  #       # Trigger the behavior that occurs when invalid params are submitted
  #       Simulator.any_instance.stub(:save).and_return(false)
  #       put :update, {:id => simulator.to_param, :simulator => {}}, valid_session
  #       response.should render_template("edit")
  #     end
  #   end
  # end

  # describe "DELETE destroy" do
  #   it "destroys the requested simulator" do
  #     simulator = Simulator.create! valid_attributes
  #     expect {
  #       delete :destroy, {:id => simulator.to_param}, valid_session
  #     }.to change(Simulator, :count).by(-1)
  #   end

  #   it "redirects to the simulators list" do
  #     simulator = Simulator.create! valid_attributes
  #     delete :destroy, {:id => simulator.to_param}, valid_session
  #     response.should redirect_to(simulators_url)
  #   end
  # end

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
        @valid_post_parameter = {:id => @simulator.to_param, "query" => params, query_id: @simulator.parameter_set_queries.first.id}
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
        assigns(:query_id).should == ParameterSetQuery.last.id
      end

      context "and with delete option" do
        it "delete the last parameter_set_query of @simulator" do
          expect {
            post :_make_query, {:id => @simulator.to_param, delete_query: "xxx", query_id: @simulator.parameter_set_queries.first.id}, valid_session
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

  describe "GET _parameter_list" do
    before(:each) do
      @simulator = FactoryGirl.create(:simulator,
                                      parameter_sets_count: 30, runs_count: 0,
                                      analyzers_count: 3, run_analysis: false,
                                      parameter_set_queries_count: 5
                                      )
      get :_parameter_list, {id: @simulator.to_param, sEcho: 1, iDisplayStart: 0, iDisplayLength:25 , iSortCol_0: 0, sSortDir_0: "asc"}, :format => :json
      @parsed_body = JSON.parse(response.body)
    end

    it "return json format" do
      response.header['Content-Type'].should include 'application/json'
      @parsed_body["iTotalRecords"].should == 30
      @parsed_body["iTotalDisplayRecords"].should == 30
    end

    it "paginates the list of parameters" do
      @parsed_body["aaData"].size.should == 25
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

        get :_parameter_list, {id: @simulator.to_param, sEcho: 1, iDisplayStart: 0, iDisplayLength:25 , iSortCol_0: 1, sSortDir_0: "desc", query_id: @query.id}, :format => :json
        @parsed_body = JSON.parse(response.body)
      end

      it "show the list of filtered ParameterSets" do
        @parsed_body["aaData"].size.should == 5
        @parsed_body["aaData"].each do |ps|
          ps[1].to_i.should >= 5 #ps[1].to_i is qeual to v.L
        end
        @parsed_body["aaData"].first[1].to_i.should == @query.parameter_sets.max("v.L")
      end
    end
  end
end
