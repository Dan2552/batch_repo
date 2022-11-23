
# Setup

```ruby
gem "batch_repo", git: "https://github.com/Dan2552/batch_repo"
```

# Usage

```
Usage:
  batch_repo clone [organisation] [directory] [archived_directory]

    Where [organisation] is the GitHub org in which to clone all
    repositories from (that you have permission to pull at least!).

    The [directory] specifies where they should be cloned to, each
    repository will be cloned to its own child directory within it.

    [archived_directory] is optional. By default archived repositories wont
    be cloned. If you supply this, they will be to the specified directory.
    This can, but doesn't have to be, the same value as [directory].

    Optional arguments:
    * --verbose
    * --pull-latest - destructively sets the main branch to match remote

  batch_repo update [script]

    Where [script] will be run agaisnt many repositories. It's recommended
    to run this in a separate directory to where you'd normally work on
    repositories. By default it'll clone a new copy to `./repos/*`.

    Note: This is a destructive action. It will force push to the target
    branch.

    The script file needs the following methods defined in a class called
    `Update`:
    * `run_on_each_repo` - the operation you want to perform on each repo
    * `branch` - the branch name (`String`)
    * `commit_message` - the commit message (`String`)
    * `repos` - the list of repositories (`Array` of `String` elements) that
      the script will actually be run agaisnt

    Optional arguments:
    * --verbose
    * --dry-run
```
