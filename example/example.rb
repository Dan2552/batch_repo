#
# Run with `bundle exec batch_repo update example.rb`
#

class Update
  def run_on_each_repo
    require "fileutils"
    FileUtils.rm(File.join(Dir.pwd, "README.md"))
  end

  def branch
    "#{Date.today.to_s}-example"
  end

  def commit_message
    "This is an example commit message"
  end

  def repos
    %w(
      Dan2552/hedgehog
      Dan2552/mundler
    )
  end
end
