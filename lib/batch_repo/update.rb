module BatchRepo
  class Update
    def initialize(script_file)
      @script_file = script_file
      @update = ::Update.new if defined?(::Update)
    end

    def valid?
      return false if (@script_file || "").strip.length == 0

      begin
        update.method(:run_on_each_repo)
        verbose_puts("found #run_on_each_repo")
        update.method(:branch)
        verbose_puts("found #branch")
        update.method(:commit_message)
        verbose_puts("found #commit_message")
        update.method(:repos)
        verbose_puts("found #repos")
      rescue Exception => e
        verbose_puts("failed: #{e.message}")
        return false
      end

      true
    end

    def run
      repos = update.repos

      repos.map { |repo| Repository.new(repo) }.each do |repo|
        puts DecoratedString.new("-------- #{repo.name} --------").bg_blue

        puts DecoratedString.new("cloning").bold.bg_cyan
        repo.clone_repo

        branch_name = update.branch
        puts DecoratedString.new("branching #{branch_name}").bold.bg_cyan
        repo.make_a_new_branch(branch_name)

        puts DecoratedString.new("running script").bold.bg_cyan
        with_clean_env do
          FileUtils.cd(repo.path.to_s)
          update.run_on_each_repo
        end

        tells = [
          "Changes not staged for commit:",
          "modified:",
          "deleted:"
        ]

        git_status = `cd #{repo.path} && git status`

        if tells.none? { |tell| git_status.include?(tell) }
          puts "no changes to commit"
          next
        end

        message = update.commit_message
        puts DecoratedString.new("committing: #{message}").bold.bg_cyan
        repo.commit(message)

        puts DecoratedString.new("publishing to #{branch_name}").bold.bg_cyan
        if ENV["DRY_RUN"] == "true"
          puts "skipped (dry run)"
        else
          repo.publish(branch_name)
        end

        puts DecoratedString.new("opening pr").bold.bg_cyan
        if ENV["DRY_RUN"] == "true"
          puts "skipped (dry run)"
        else
          repo.open_pr
        end
      end
    end

    private

    def verbose_puts(str)
      if ENV["VERBOSE"] == "true"
        puts str
      end
    end

    def with_clean_env(&blk)
      if defined?(Bundler) && Bundler.respond_to?(:with_unbundled_env)
        Bundler.with_unbundled_env(&blk)
      elsif defined?(Bundler)
        Bundler.with_clean_env(&blk)
      else
        blk.call
      end
    end

    def update
      @update ||= begin
        if @script_file.start_with?("/")
          verbose_puts("loading absolute: #{@script_file}")
          require @script_file
        else
          relative = File.join(ENV["BATCH_REPO_ROOT"] || Bundler.root, @script_file)
          verbose_puts("loading relative: #{relative}")

          require_relative relative
        end
      rescue LoadError, NameError => e
        verbose_puts("failed: #{e.message}")
        return false
      end

      ::Update.new
    end
  end
end
