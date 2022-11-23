module Security
  def self.set_keychain_password(account_name, username, password)
    system("security add-generic-password -s #{account_name} -a \"#{username}\" -w \"#{password}\" -U") ||
      raise("Failed to save password in keychain.")
  end

  def self.get_keychain_password(account_name)
    `security find-generic-password -gs #{account_name} 2>&1 >/dev/null | ruby -e 'print $1 if STDIN.gets =~ /^password: "(.*)"$/'`.strip
  end

  def self.get_keychain_username(account_name)
    `security find-generic-password -gs #{account_name} 2>/dev/null | grep '"acct"' | grep '=' | ruby -e 'print $1 if STDIN.gets =~ /"acct".*="(.*)"$/'`.strip
  end

  def self.find_or_create(account_name)
    user = get_keychain_username(account_name)
    pass = get_keychain_password(account_name)

    if user.length == 0 || pass.length == 0 || ENV["REAUTH_BATCH_REPO"] == "true"
      unless STDIN.tty?
        puts "WARNING: skipped authentication because not tty"
        return ["", ""]
      end

      puts "Enter your GitHub email:"
      print "> "
      user = STDIN.gets.chomp.strip
      exit_with_message("No user supplied") unless user.length > 0

      puts "Enter your GitHub *token* (with repo access):"
      print "> "
      pass = STDIN.noecho(&:gets).chomp.strip
      exit_with_message("No password supplied") unless pass.length > 0

      set_keychain_password(account_name, user, pass)
      puts ""
    end

    [user, pass]
  end
end
