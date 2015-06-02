class SchedulerWrapper

  TYPES = ["xsub"]

  attr_reader :type

  def initialize(host)
    unless TYPES.include?(host.scheduler_type)
      raise ArgumentError.new("type must be selected from #{TYPES.inspect}")
    end
    @type = host.scheduler_type
    @work_base_dir = Pathname.new(host.work_base_dir)
  end

  def submit_command(script, run_id, job_parameters = {})
    work_dir = @work_base_dir.join(run_id)
    case @type
    when "xsub"
      scheduler_log_dir = @work_base_dir.join(run_id+"_log")
      escaped = Shellwords.escape(job_parameters.to_json)
      # escaped = job_parameters.to_json.gsub("'","'\\\\''")
      "bash -l -c 'echo XSUB_BEGIN && xsub #{script} -d #{work_dir} -l #{scheduler_log_dir} -p #{escaped}'"
    else
      raise "not supported"
    end
  end

  def parse_jobid_from_submit_command(output)
    case @type
    when "xsub"
      xsub_out = extract_xsub_output(output)
      JSON.load(xsub_out)["job_id"]
    else
      raise "not supported"
    end
  end

  def all_status_command
    case @type
    when "xsub"
      "bash -l -c 'xstat'"
    else
      raise "not supported"
    end
  end

  def status_command(job_id)
    case @type
    when "xsub"
      "bash -l -c 'echo XSUB_BEGIN && xstat #{job_id}'"
    else
      raise "not supported"
    end
  end

  def parse_remote_status(stdout)
    return :unknown if stdout.empty?
    case @type
    when "xsub"
      xsub_out = extract_xsub_output(stdout)
      case JSON.load(xsub_out)["status"]
      when "queued"
        :submitted
      when "running"
        :running
      when "finished"
        :includable
      else
        raise "unknown status"
      end
    else
      raise "not supported"
    end
  end

  def cancel_command(job_id)
    case @type
    when "xsub"
      "bash -l -c 'xdel #{job_id}'"
    else
      raise "not supported"
    end
  end

  def scheduler_log_file_paths(run)
    paths = []
    dir = Pathname.new(@work_base_dir)
    case @type
    when "xsub"
      paths << dir.join("#{run.id}_log")
    else
      raise "not supported type"
    end
    paths
  end

  private
  def extract_xsub_output(output)
    output_lines = output.lines.to_a
    idx = output_lines.index {|line| line =~ /^XSUB_BEGIN$/ }
    output_lines[(idx+1)..-1].join
  end
end
