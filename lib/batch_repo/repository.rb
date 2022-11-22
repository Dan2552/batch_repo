class Repository
  def initialize(org_and_repo)
    @org, @repo = org_and_repo.split("/")
  end

  def find_and_replace(path, original, replacement)
    text = File.read(path)
    replace = text.gsub(original, replacement)
    if text != replace
      File.open(path, 'w') { |file| file.puts(replace) }
    end
  end

  def clone_repo
    return if File.directory?(path)

    root = ENV["BATCH_REPO_ROOT"] || Bundler.root
    repos_path = File.join(root, "repos")
    FileUtils.mkdir_p(repos_path)
    FileUtils.cd(repos_path)
    if ENV["VERBOSE"] == "true"
      system("git clone https://github.com/#{org}/#{repo}.git") || fail!
    else
      system("git clone https://github.com/#{org}/#{repo}.git >/dev/null 2>&1") || fail!
    end
  end

  def make_a_new_branch(branch_name)
    root = ENV["BATCH_REPO_ROOT"] || Bundler.root
    repos_path = File.join(root, "repos")
    unless File.directory?(File.join(repos_path, "gathering-of-scripts"))
      Repository.new("Dan2552/gathering-of-scripts").clone_repo
    end

    branch = File.join(repos_path, "gathering-of-scripts", "git", "branch")

    cd_to_repo
    if ENV["VERBOSE"] == "true"
      system("#{branch} master --prefer=remote --discard=true") || fail!
      system("#{branch} #{branch_name} --prefer=remote --discard=true ") || fail!
    else
      system("#{branch} master --prefer=remote --discard=true >/dev/null 2>&1") || fail!
      system("#{branch} #{branch_name} --prefer=remote --discard=true >/dev/null 2>&1") || fail!
    end
    system("git reset --hard origin/master >/dev/null")
  end

  def publish(branch_name)
    cd_to_repo
    fail! if branch_name == "master"
    fail! if branch_name.nil?
    fail! if branch_name.length == 0

    system("git push -u origin #{branch_name} --force")
  end

  def open_pr
    root = ENV["BATCH_REPO_ROOT"] || Bundler.root
    repos_path = File.join(root, "repos")
    unless File.directory?(File.join(repos_path, "gathering-of-scripts"))
      Repository.new("Dan2552/gathering-of-scripts").clone_repo
    end

    open_pr_bin = File.join(repos_path, "gathering-of-scripts", "github", "open-pr")

    cd_to_repo
    system("#{open_pr_bin} master")
  end

  def commit(message)
    cd_to_repo
    system("git add .")
    system("git commit -a -m \"#{message}\" >/dev/null") || (system("git status") && fail!)
  end

  def amend
    cd_to_repo
    system("git add .")
    system("git commit --amend")
  end

  def path
    root = ENV["BATCH_REPO_ROOT"] || Bundler.root
    File.join(root, "repos", name)
  end

  def name
    repo.split("/").last
  end

  private

  attr_reader :repo
  attr_reader :org

  def fail!
    STDERR.puts "Failed"
    exit 1
  end

  def cd_to_repo
    FileUtils.cd(path)
  end
end
