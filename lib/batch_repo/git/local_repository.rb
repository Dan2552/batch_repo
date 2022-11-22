module BatchRepo
  class LocalRepository
    def self.where(root_directory:)
      Dir.glob(::File.join(root_directory, "**/.git"))
        .map { |repo| repo.split(/\/.git$/).first }
        .map { |repo| new(repo) }
    end

    def initialize(repository)
      @repository = repository
    end

    def checkout(branch, new_branch: false)
      in_repository do
        branch = default_branch if branch == :default

        if new_branch
          system("git checkout -b #{branch} >/dev/null 2>/dev/null")
        else
          system("git checkout #{branch} >/dev/null 2>/dev/null")
        end
      end
    end

    def fetch
      in_repository do
        system("git fetch >/dev/null 2>/dev/null")
      end
    end

    def add_all
      in_repository do
        system("git add . -A >/dev/null 2>/dev/null")
      end
    end

    def reset(mode, upstream, branch)
      in_repository do
        branch = default_branch if branch == :default
        system("git reset --#{mode} #{upstream}/#{branch} >/dev/null 2>/dev/null")
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
        system("git push origin #{local_branch} >/dev/null")
      end
    end

    # Helper
    def branch(branch_name)
      fetch
      checkout(:default)
      add_all
      reset(:hard, "origin", :default)
      checkout(branch_name, new_branch: true)
    end

    def github
      BatchRepo::GitHub::LocalRepository.new(repository)
    end

    def path
      repository
    end

    def to_s
      inspect
    end

    def inspect
      "<Repo #{repository}>"
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
