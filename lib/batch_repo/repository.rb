module BatchRepo
  class Repository
    def initialize(org_and_repo, path: nil, parent_path: nil)
      @org, @repo = org_and_repo.split("/")

      if path && parent_path
        raise "path and parent_path should be exclusive options"
      elsif path
        @path = path
      elsif parent_path
        @path = File.join(parent_path, @repo)
      else
        raise "path or parent_path must be specified"
      end
    end

    attr_accessor :path

    def name
      @repo
    end

    def clone_repo
      success = true

      return if File.directory?(File.join(path, ".git"))

      success = false

      FileUtils.rm_rf(path)
      FileUtils.mkdir_p(parent_path)

      if ENV["VERBOSE"] == "true"
        system("cd #{parent_path} && git clone https://github.com/#{org}/#{repo}.git") || fail!("Failed to clone")
      else
        system("cd #{parent_path} && git clone https://github.com/#{org}/#{repo}.git >/dev/null 2>&1") || fail!("Failed to clone")
      end

      success = true
    ensure
      FileUtils.rm_rf(path) if success == false
    end

    def switch_to_remote_main!
      clone_repo

      success = false

      system("cd #{path} && git remote prune origin >/dev/null 2>/dev/null")

      if ENV["VERBOSE"] == "true"
        Branch.switch(main_branch_name, path: path) || fail!("Failed to switch to #{main_branch_name}")
      else
        Branch.switch(main_branch_name, path: path) || fail!("Failed to switch to #{main_branch_name}")
      end
    end

    def make_a_new_branch(branch_name)
      switch_to_remote_main!

      if ENV["VERBOSE"] == "true"
        Branch.switch(branch_name, path: path) || fail!("Failed to switch to #{branch_name}")
        system("cd #{path} && git reset --hard origin/#{main_branch_name}")
      else
        Branch.switch(branch_name, path: path) || fail!("Failed to switch to #{branch_name}")
        system("cd #{path} && git reset --hard origin/#{main_branch_name} >/dev/null")
      end
    end

    def publish(branch_name)
      fail! if branch_name == "#{main_branch_name}"
      fail! if branch_name.nil?
      fail! if branch_name.length == 0

      system("cd #{path} && git push -u origin #{branch_name} --force")
    end

    def open_pr
      open_pr_bin = File.join(gathering_path, "github", "open-pr")
      system("cd #{path} && #{open_pr_bin} #{main_branch_name}")
    end

    def commit(message)
      system("cd #{path} && git add .")
      system("cd #{path} && git commit -a -m \"#{message}\" >/dev/null") || (system("cd #{path} && git status") && fail!)
    end

    private

    SEMAPHORE = Mutex.new

    attr_reader :repo
    attr_reader :org

    def fail!(message = nil)
      prefix = "#{org}/#{repo} (#{path}): "
      message ||= "Failed"
      STDERR.puts(prefix + message)
      exit 1
    end

    def parent_path
      File.expand_path(File.join(path, ".."))
    end

    def gathering_path
      path = File.join("/tmp", "gathering-of-scripts")

      SEMAPHORE.synchronize do
        unless File.directory?(path)
          Repository.new("Dan2552/gathering-of-scripts", path: path).clone_repo
        end
      end

      path
    end

    def main_branch_name
      original = Dir.pwd
      FileUtils.cd(path)
      name = `basename $(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null) 2>/dev/null`.chomp.strip
      name = "master" if name.length == 0
      name
    ensure
      FileUtils.cd(original)
    end
  end
end
