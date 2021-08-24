require "pathname"

module BatchRuby
  class LocalGithubRepo
    def initialize(repository)
      @repository = repository
    end

    def open_pull_request!
      git = Git.new(repository)

      in_repository do
        url = `git config --get remote.origin.url`.strip
        url.gsub!("git@", "https://")
        url.gsub!(":", "/")
        url.gsub!(".git", "")
        url.gsub!("https///", "https://")
        url = "#{url}/compare/#{git.default_branch}...#{git.local_branch}"
        system("open #{url}")
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
