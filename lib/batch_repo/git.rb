module BatchRuby
  class Git
    def initialize(repository)
      @repository = repository
    end

    def checkout(branch, new_branch: false)
      in_repository do
        branch = default_branch if branch == :default

        if new_branch
          system("git checkout -b #{branch}")
        else
          system("git checkout #{branch}")
        end
      end
    end

    def add_all
      in_repository do
        system("git add . -A")
      end
    end

    def reset(mode, upstream, branch)
      in_repository do
        branch = default_branch if branch == :default
        system("git reset --#{mode} #{upstream}/#{branch}")
      end
    end

    # Returns true if it commits
    #
    def commit(message)
      in_repository do
        output = `git commit -m \"#{message}\"`
        $?.exitstatus == 0 && !output.include?("nothing to commit")
      end
    end

    def default_branch
      in_repository do
        `basename $(git symbolic-ref refs/remotes/origin/HEAD)`.chomp
      end
    end

    def local_branch
      in_repository do
        `git rev-parse --abbrev-ref HEAD`.chomp
      end
    end

    def push
      raise "Did you really mean to use master?" if local_branch == "master"

      in_repository do
        system("git push origin #{local_branch}")
      end
    end

    private

    attr_reader :repository

    def in_repository(&blk)
      old_dir = Dir.pwd
      FileUtils.cd(repository)

      begin
        yield
      ensure
        FileUtils.cd(old_dir)
      end
    end
  end
end
