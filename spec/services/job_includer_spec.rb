require 'spec_helper'

describe JobIncluder do

  def make_valid_archive_file(run, keep_work_dir = false)
    Dir.chdir(@temp_dir) {
      work_dir = Pathname.new(run.id.to_s)
      make_valid_work_dir(work_dir)
      archive_path = Pathname.new("#{run.id}.tar.bz2")
      system("tar cjf #{archive_path} #{work_dir}")
      FileUtils.remove_entry_secure(work_dir) unless keep_work_dir
      @archive_full_path = archive_path.expand_path
    }
  end

  def make_valid_work_dir(work_dir)
    FileUtils.mkdir(work_dir)
    Dir.chdir(work_dir) {
      File.open("_status.json", 'w') {|io|
        status = {
          "hostname" => "hostXXX",
          "started_at" => DateTime.now, "finished_at" => DateTime.now,
          "rc" => 0
        }
        io.puts status.to_json
        io.flush
      }
      File.open("_time.txt", 'w') {|io|
        io.puts "real 10.00\nuser 8.00\nsys 2.00"
        io.flush
      }
      FileUtils.touch("_stdout.txt")
    }
  end

  def make_scheduler_log(host, run)
    log_dir = @temp_dir.join(@run.id.to_s+'_log')
    FileUtils.mkdir_p(log_dir)
    FileUtils.touch(log_dir.join('scheduler_log'))
  end

  before(:each) do
    @sim = FactoryGirl.create(:simulator,
                              parameter_sets_count: 1, runs_count: 0,
                              command: "sleep 1")
    @temp_dir = Pathname.new( Dir.mktmpdir )
  end

  after(:each) do
    FileUtils.remove_entry_secure(@temp_dir) if File.directory?(@temp_dir)
  end

  shared_examples_for "included correctly" do

    it "copies reuslt files into the run directory" do
      include_job
      expect(@run.dir.join("_stdout.txt")).to be_exist
    end

    it "copies archive result file" do
      include_job
      expect(@run.dir.join("..", File.basename(@archive_full_path))).to be_exist
    end

    it "parses _status.json" do
      include_job
      expect(@run.hostname).to eq "hostXXX"
      expect(@run.started_at).to be_a(DateTime)
      expect(@run.finished_at).to be_a(DateTime)
      expect(@run.status).to eq :finished
    end

    it "parses _time.txt" do
      include_job
      expect(@run.cpu_time).to be_within(0.01).of(8.0)
      expect(@run.real_time).to be_within(0.01).of(10.0)
    end

    it "deletes archive file after the inclusion finishes" do
      include_job
      expect(@archive_full_path).not_to be_exist
    end

    it "invokes create_auto_run_analyses" do
      expect(JobIncluder).to receive(:create_auto_run_analyses)
      include_job
    end
  end

  describe "manual job" do

    before(:each) do
      @run = @sim.parameter_sets.first.runs.create(submitted_to: nil)
      expect(ResultDirectory.manual_submission_job_script_path(@run)).to be_exist
      make_valid_archive_file(@run)
    end

    let(:include_job) { JobIncluder.include_manual_job(@archive_full_path, @run) }

    it_behaves_like "included correctly"

    it "deletes job script after inclusion" do
      include_job
      expect(ResultDirectory.manual_submission_job_script_path(@run)).not_to be_exist
    end
  end

  describe "remote job" do

    before(:each) do
      @host = @sim.executable_on.where(name: "localhost").first
      @host.work_base_dir = @temp_dir.expand_path
      @host.save!
      @run = @sim.parameter_sets.first.runs.create(submitted_to: @host)
      make_scheduler_log(@host, @run)
    end

    describe "correct case" do

      before(:each) do
        make_valid_archive_file(@run)
      end

      let(:include_job) { JobIncluder.include_remote_job(@host, @run) }

      it_behaves_like "included correctly"

      it "call SSHUtil.download" do
        expect(SSHUtil).to receive(:download).and_call_original
        include_job
      end

      it "includes scheduler_log" do
        include_job
        expect(@run.dir.join(@run.id.to_s+'_log', 'scheduler_log')).to be_exist
      end
    end

    describe "mounted_work_base_dir is not empty" do

      before(:each) do
        @host.mounted_work_base_dir = @host.work_base_dir
        @host.save
        make_valid_archive_file(@run, true)
      end

      let(:include_job) { JobIncluder.include_remote_job(@host, @run) }

      it_behaves_like "included correctly"

      it "deletes remote work_dir and archive file" do
        work_dir = File.join(@temp_dir, @run.id.to_s)
        expect {
          include_job
        }.to change { File.directory?(work_dir) }.from(true).to(false)
      end

      it "does not call SSHUtil.download" do
        expect(SSHUtil).to_not receive(:download)
        include_job
      end

      it "includes scheduler_log" do
        include_job
        expect(@run.dir.join(@run.id.to_s+'_log', 'scheduler_log')).to be_exist
      end
    end

    # A test case for error handling
    # Even if .tar.bz2 is not found, try to include the files as much as possible
    describe "when archive file is not found but work_dir exists" do

      context "if _status.json exists in downloded work_dir" do

        before(:each) do
          make_valid_archive_file(@run, true)
          FileUtils.rm(@archive_full_path)
          JobIncluder.include_remote_job(@host, @run)
          @run.reload
        end

        it "updates status to finished" do
          expect(@run.status).to eq :finished
        end

        it "copies files in work_dir" do
          expect(@run.dir.join("_stdout.txt")).to be_exist
        end

        it "does not copy archive file" do
          expect(@run.dir.join('..', @run.id.to_s+'.tar.bz2')).not_to be_exist
        end

        it "deletes remote work_dir and archive file" do
          expect(Dir.entries(@temp_dir)).to match_array(['.', '..'])
        end
      end

      context "if _status.json does not exist in downloded work_dir" do

        before(:each) do
          make_valid_archive_file(@run, true)
          FileUtils.rm( @temp_dir.join(@run.id.to_s,"_status.json") )
          FileUtils.rm( @archive_full_path )
          JobIncluder.include_remote_job(@host, @run)
          @run.reload
        end

        it "updates status to failed" do
          expect(@run.status).to eq :failed
        end
      end
    end
  end

  describe ".create_auto_run_analyses" do

    def invoke
      JobIncluder.send(:create_auto_run_analyses, @run)
    end

    before(:each) do
      @run = @sim.parameter_sets.first.runs.create
      @run.update_attribute(:status, :finished)
    end

    describe "auto run of analyzers for on_run type" do

      before(:each) do
        @azr = FactoryGirl.create(:analyzer, simulator: @sim, type: :on_run)
      end

      context "when Analyzer#auto_run is :yes" do

        before(:each) { @azr.update_attribute(:auto_run, :yes) }

        it "creates analysis if status is 'finished'" do
          expect { invoke }.to change { @run.reload.analyses.count }.by(1)
        end

        it "do not create analysis if status is not 'finished'" do
          @run.update_attribute(:status, :failed)
          expect { invoke }.to_not change { @run.reload.analyses.count }
        end
      end

      context "when Analyzer#auto_run is :no" do

        before(:each) { @azr.update_attribute(:auto_run, :no) }

        it "does not create analysis if Anaylzer#auto_run is :no" do
          @azr.update_attributes!(auto_run: :no)
          expect { invoke }.to_not change { @run.reload.analyses.count }
        end
      end

      context "when Analyzer#auto_run is :first_run_only" do

        before(:each) { @azr.update_attributes!(auto_run: :first_run_only) }

        it "creates analysis if the run is the first 'finished' run within the parameter set" do
          expect { invoke }.to change { @run.reload.analyses.count }.by(1)
        end

        it "does not create analysis if 'finished' run already exists within the paramter set" do
          FactoryGirl.create(:run, parameter_set: @run.parameter_set, status: :finished)
          expect { invoke }.to_not change { @run.reload.analyses.count }
        end
      end
    end

    describe "auto run of analyzers for on_parameter_set type" do

      before(:each) do
        @azr = FactoryGirl.create(:analyzer, simulator: @sim, type: :on_parameter_set)
      end

      context "when Analyzer#auto_run is :yes" do

        before(:each) { @azr.update_attribute(:auto_run, :yes) }

        it "creates analysis if all the other runs within the parameter set are 'finished' or 'failed'" do
          FactoryGirl.create(:run, parameter_set: @run.parameter_set, status: :failed)
          FactoryGirl.create(:run, parameter_set: @run.parameter_set, status: :finished)
          expect { invoke }.to change { @run.parameter_set.reload.analyses.count }.by(1)
        end

        it "does not create analysis if any of runs within the parameter set is not 'finished' or 'failed'" do
          FactoryGirl.create(:run, parameter_set: @run.parameter_set, status: :submitted)
          expect { invoke }.to_not change { @run.parameter_set.reload.analyses.count }
        end
      end

      context "when Analyzer#auto_run is :no" do

        before(:each) { @azr.update_attribute(:auto_run, :no) }

        it "does not create analysis even if all the other runs are finished" do
          FactoryGirl.create(:run, parameter_set: @run.parameter_set, status: :finished)
          expect { invoke }.to_not change { @run.parameter_set.reload.analyses.count }
        end
      end
    end
  end
end
