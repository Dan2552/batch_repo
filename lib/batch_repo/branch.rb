module Branch
  def self.switch(target_branch, path: nil)
    path ||= Dir.pwd

    system("cd #{path} && git reset --mixed") &&
    system("cd #{path} && git add . -A") &&
    system("cd #{path} && git fetch") &&
    system("cd #{path} && git reset --hard") &&
    (
      system("cd #{path} && git checkout #{target_branch}") ||
      system("cd #{path} && git checkout -b #{target_branch}")
    ) &&
    system("cd #{path} && git branch --set-upstream-to=origin/#{target_branch} || :") &&
    system("cd #{path} && git reset --hard origin/#{target_branch} || :")
  end
end
