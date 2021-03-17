require "pathname"

module BatchRuby
  class GitHub
    def initialize(repository)
      @repository = repository
      ignore_directories_without_a_git_folder!
    end

    def open_pull_request!
      git = Git.new(repository)
      url = `git config --get remote.origin.url`.strip
      url.gsub!("git@", "https://")
      url.gsub!(":", "/")
      url.gsub!(".git", "")
      url.gsub!("https///", "https://")
      url = "#{url}/compare/#{git.default_branch}...#{git.local_branch}"
      system("open #{url}")
    end

    private

    attr_reader :repository
  end
end
