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
        !output.include?("nothing to commit")
      end
    end

    def default_branch
      in_repository do
        `basename $(git symbolic-ref refs/remotes/origin/HEAD)`.chomp
      end
    end

    def local_branch
      `git rev-parse --abbrev-ref HEAD`.chomp
    end

    private

    attr_reader :repositories

    def in_repository(&blk)
      FileUtils.cd(repository)
      yield
    end
  end
end
