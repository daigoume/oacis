class RunsController < ApplicationController

  def show
    @run = Run.find(params[:id])
    @param_set = @run.parameter_set
    @analyses = @run.analyses
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @run }
    end
  end

  def create
    @param_set = ParameterSet.find(params[:parameter_set_id])

    num_runs = 1
    num_runs = params[:num_runs].to_i if params[:num_runs]
    raise 'params[:num_runs] is invalid' unless num_runs > 0

    @runs = []
    num_runs.times do |i|
      run = @param_set.runs.build(params[:run])
      @runs << run
    end

    respond_to do |format|
      if @runs.all? { |run| run.save }
        format.html {
          message = "#{@runs.count} run#{@runs.size > 1 ? 's were' : ' was'} successfully created"
          redirect_to @param_set, notice: message
        }
        format.json { render json: @runs, status: :created, location: @param_set}
      else
        format.html { redirect_to @param_set, error: 'Failed to create a run.'}
        format.json {
          render json: @runs.map{ |r| r.errors }, status: :unprocessable_entity
        }
      end
    end
  end

end
