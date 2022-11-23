module BatchRepo
  class Clone
    def run(organisation, directory, archive_directory)
      # run before to ensure auth is setup before threads start
      auth

      threads = []
      covered = []

      max_pages = ENV["MAX_GITHUB_PAGES"].to_i
      pull_latest = ENV["PULL_LATEST"] == "true"
      thread_count = ENV["THREAD_COUNT"].to_i
      verbose = ENV["VERBOSE"] == "true"


      FileUtils.mkdir_p(directory)
      FileUtils.mkdir_p(archive_directory) if archive_directory

      tracker_thread = Thread.new do
        if verbose
          last_remaining = -1
          loop do
            sleep 0.5
            alive_threads = threads.select(&:alive?).count
            if last_remaining != alive_threads
              puts "Active threads: #{alive_threads}"
              last_remaining = alive_threads
            end
          end
        end
      end

      max_pages.times do |n|
        json = fetch(organisation, n)

        names = json
          .select { |app| app["archived"] != true }
          .map { |g| g["full_name"] }

        archived_names = json
          .select { |app| app["archived"] == true }
          .map { |g| g["full_name"] }

        # Discontinue if empty page
        break if names.empty? && archived_names.empty?

        names.each do |name|
          wait_until { threads.select(&:alive?).count < thread_count }

          covered << name

          threads << Thread.new do
            puts "#{name}"
            repository = Repository.new(name, parent_path: directory)
            repository.clone_repo
            repository.switch_to_remote_main! if pull_latest
          end
        end

        if archive_directory
          archived_names.each do |name|
            wait_until { threads.select(&:alive?).count < thread_count }

            threads << Thread.new do
              next unless name.length > 1
              puts "#{name} (archived)"
              repository = Repository.new(name, parent_path: archive_directory)
              repository.clone_repo
              repository.switch_to_remote_main! if pull_latest
            end
          end
        end
      end

      puts "Finishing..."

      threads.each(&:join)
      tracker_thread.kill

      puts "Done"
    end

    private

    def auth
      @auth ||= begin
        return ENV["GITHUB_AUTH"] if ENV["GITHUB_AUTH"]
        user, pass = Security.find_or_create("GitHub - https://api.github.com")
        Base64.strict_encode64([user, pass].join(":"))
      end
    end

    def fetch(organisation, page)
      uri = URI("https://api.github.com/orgs/#{organisation}/repos?type=all&per_page=999&page=#{page}")
      request = Net::HTTP::Get.new(uri)

      request["Authorization"] = "Basic #{auth}"
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      json = JSON.parse(response.body)

      if response.header["x-oauth-client-id"].nil?
        puts "WARNING: unauthenticated with GitHub, will only fetch public repositories. Run with `REAUTH_BATCH_REPO=true` to force reprompt of keychain password."
      end

      if json.is_a?(Hash) && json["message"] == "Not Found"
        uri = URI("https://api.github.com/users/#{organisation}/repos?type=all&per_page=999&page=#{page}")
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Basic #{auth}"
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end

        json = JSON.parse(response.body)
      end

      json
    end

    def wait_until
      Timeout.timeout(60 * 30) do
        sleep(0.1) until value = yield
        value
      end
    end

    def bail!(message)
      STDERR.puts(message)
      exit(1)
    end
  end
end
