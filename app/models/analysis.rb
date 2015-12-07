class Analysis
  include Mongoid::Document
  include Mongoid::Timestamps
  include Submittable

  field :parameters, type: Hash

  belongs_to :analyzer
  belongs_to :analyzable, polymorphic: true, autosave: false
  belongs_to :parameter_set

  default_scope ->{ where(:to_be_destroyed.in => [nil,false]) }

  validates :analyzer, :presence => true
  validate :cast_and_validate_parameter_values

  before_create :assign_parameter_set_id
  after_create :create_dir
  before_destroy :delete_dir

  public
  def dir
    ResultDirectory.analysis_path(self)
  end

  def executable
    analyzer
  end

  # returns result files and directories
  def result_paths
    paths = Dir.glob( dir.join('*') ).map {|x|
      Pathname(x)
    }
    return paths
  end

  def archived_result_path
    dir.join('..', "#{id}.tar.bz2")
  end

  # returns an hash object which is going to be dumped into _input.json
  def input
    obj = {}
    obj[:analysis_parameters] = self.parameters
    case self.analyzer.type
    when :on_run
      run = self.analyzable
      obj[:simulation_parameters] = run.parameter_set.v
    when :on_parameter_set
      ps = self.analyzable
      obj[:simulation_parameters] = ps.v
      run_ids = ps.runs.where(status: :finished).only(:id).map {|r| r.id.to_s}
      obj[:run_ids] = run_ids
    else
      raise "not supported type"
    end
    return obj
  end

  def args
    if analyzer.support_input_json
      ""
    else
      params = analyzer.parameter_definitions.map do |pd|
        parameters[pd.key]
      end
      params.join(' ')
    end
  end

  # returns an array
  #   array of run.results_paths or run.dir(s) to be linked to _input/
  def input_files
    files = []
    case self.analyzer.type
    when :on_run
      run = self.analyzable
      files = run.result_paths
      # TODO: add directories of dependent analysis
    when :on_parameter_set
      ps = self.analyzable
      run_ids = ps.runs.where(status: :finished).only(:id).map {|run| run.id.to_s}
      base_dir = ps.runs.where(status: :finished).first.dir.join('../')
      files = run_ids.map {|run_id| base_dir.join(run_id)}
    else
      raise "not supported type"
    end
    return files
  end

  def destroyable?
    true
  end

  def set_lower_submittable_to_be_destroyed
    # do nothing
  end

  private
  def cast_and_validate_parameter_values
    return unless analyzer
    defn = analyzer.parameter_definitions
    casted = ParametersUtil.cast_parameter_values(parameters, defn, errors)
    if casted.nil?
      errors.add(:parameters, "parameters are invalid. See the definition.")
      return
    end
    self.parameters = casted
  end

  def assign_parameter_set_id
    if analyzable.is_a?(Run)
      self.parameter_set = analyzable.parameter_set
    elsif analyzable.is_a?(ParameterSet)
      self.parameter_set = analyzable
    else
      raise "must not happen"
    end
  end

  def create_dir
    FileUtils.mkdir_p(self.dir)
  end

  def delete_dir
    # if self.analyzable_id.nil, parent Analyzable item is already destroyed.
    # Therefore, self.dir raises an exception
    if self.analyzable && !self.analyzable.destroyed? && File.directory?(self.dir)
      FileUtils.rm_r(self.dir)
    end
  end
end
