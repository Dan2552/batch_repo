require "pathname"

module BatchRuby
  class Bundler
    def initialize(gemfiles)
      @gemfiles = Array(gemfiles)
    end

    # Updates multiple `Gemfile`s to update a given gem. Even if the gem has a
    # `tag:` flag (e.g. if it's a GitHub/internal one).
    #
    def update(updated_gem = "*", version = "*")
      @updated_gem = updated_gem
      @version = version

      create_new_branch_based_off_default!
      bundle!
      commit_and_pull_request!
    end

    private

    attr_reader :gemfiles
    attr_reader :updated_gem
    attr_reader :version

    def create_new_branch_based_off_default!
      repositories.each do |repository|
        git = Git.new(repository)
        git.checkout(:default)
        git.add_all
        git.reset(:hard, "origin", :default)
        git.checkout(branch_name, new_branch: true)
      end
    end

    # Returns true if it updated the Gemfile
    #
    def update_gemfile!(gemfile)
      return false unless File.file?(gemfile)

      old_line = /(gem\s*["|']#{updated_gem}["|'],\s*organisation:\s*["|']#{updated_gem}["|'],\s*tag:\s*["|'])(\d+\.\d+\.\d+)(["|'])/
      new_line = '\1' + version + '\3'
      BatchRuby::Files.find_and_replace(gemfile, old_line, new_line)
    end

    def bundle!
      ::Bundler.with_unbundled_env do
        in_each_repository do
          if updated_gem == "*" && version == "*" # if updating everything
            system("bundle update") || raise("Bundle failed in #{Dir.pwd}")
          elsif updated_gem != "*" && version == "*" # if updating one gem, but no specific version
            system("bundle update #{updated_gem}") || raise("Bundle failed in #{Dir.pwd}")
          elsif updated_gem != "*" && version != "*" # specific gem, specific version (and therefore the Gemfile should be updated)
            if update_gemfile!(File.join(Dir.pwd, "Gemfile"))
              system("bundle install") || raise("Bundle failed in #{Dir.pwd}")
            end
          else
            raise "What are you doing?"
          end
        end
      end
    end

    def commit_and_pull_request!
      repositories.each do |repository|
        git = Git.new(repository)
        git.add_all
        if git.commit(commit_name)
          git.push
          LocalGithubRepo.new(repository).open_pull_request!
        end
      end
    end

    def repositories
      gemfiles.map do |gemfile|
        Pathname.new(gemfile).dirname
      end.select do |repository|
        File.directory?(File.join(repository, ".git"))
      end
    end

    def in_each_repository(&blk)
      repositories.each do |repository|
        old_dir = Dir.pwd
        FileUtils.cd(repository)

        begin
          yield
        ensure
          FileUtils.cd(old_dir)
        end
      end
    end

    def branch_name
      gem_name = updated_gem
      gem_name = "all-gems" if updated_gem == "*"
      timecode = Time.now.to_i
      "update-#{gem_name}-#{timecode}".gsub("_", "-")
    end

    def commit_name
      if updated_gem == "*" && version == "*" # if updating everything
        "Bundle update"
      elsif updated_gem != "*" && version == "*" # if updating one gem, but no specific version
        "Bundle update #{updated_gem}"
      elsif updated_gem != "*" && version != "*" # specific gem, specific version (and therefore the Gemfile should be updated)
        "Update #{updated_gem} to #{version}"
      end
    end
  end
end
