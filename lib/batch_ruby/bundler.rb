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

      create_new_branch_based_off_default!
      update_gemfile!
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

    def update_gemfile!
      return if updated_gem == "*"
      return if version == "*"

      gemfiles.each do |gemfile|
        old_line = /(gem\s*["|']#{updated_gem}["|'],\s*sohohouse:\s*["|']#{updated_gem}["|'],\s*tag:\s*["|'])(\d.\d.\d)(["|'])/
        new_line = '\1' + version + '\3'
        BatchRuby::File.find_and_replace(gemfile, old_line, new_line)
      end
    end

    def bundle!
      in_each_repository do
        if updated_gem == "*" && version == "*" # if updating everything
          system("bundle update")
        elsif updated_gem != "*" && version == "*" # if updating one gem, but no specific version
          system("bundle update #{updated_gem}")
        elsif updated_gem != "*" && version != "*" # specific gem, specific version (and therefore the Gemfile should be updated)
          system("bundle install")
        else
          raise "What are you doing?"
        end
      end
    end

    def commit_and_pull_request!
      repositories.each do |repository|
        if Git.new(repository).commit!(commit_name)
          Git.new(repository).push!
          Github.new(repository).open_pull_request!
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
        FileUtils.cd(repository)
        yield
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
