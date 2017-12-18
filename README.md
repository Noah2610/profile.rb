# profile.rb v2
#### by Noah Rosenzweig
---
This is the second version of my small profiling script written in Ruby.  
It's main use is for configs / dotfiles.  
If you use multiple machines which share the same configs but with differences between configs then this script could be useful.  
  
The base concept of this script is to have markers in your configs (as comments)  
that tell the script which profile this config snippet is associated to.  
When the script is executed, it will then either **comment out** or **uncomment** those snippets,  
according to what profile you want to use.

## Setup
Inside *profile.rb* you should set some variables, for example:
```ruby
### File aliases you can use from command line
file_aliases = {
  bashrc:  "~/.bashrc",
  vimrc:   "~/.vimrc"
}

### Default files that will be processed if none are given from command line
files = [
  file_aliases[:bashrc],
  "~/path/to/config"
]

# Line ~50
### Default profile(s) to use according to your machine's hostname, unless profiles are given on command line
case `hostname`.strip
when 'my-desktop'
  profiles =     ["desktop", "main"]
when 'main-laptop', 'other-laptop'
  profiles =     ["laptop"]
when 'work-machine'
  profiles =     ["work"]
  profiles_not = ["main"]    # Everything that isn't profile 'main'
                             # not recommend, because it allows ALL profiles except 'main'
else
  profile = ["default"]
end
```

## Usage
Inside your configs you can have syntax like this:
```sh
#PROFILE=desktop && main
set -o vi    # For profiles desktop AND main, only effects next line (this line)

#PROFILE_START=laptop || default
# Everything between PROFILE_START and PROFILE_END is effected
export PATH="$HOME/bin:$PATH"
export EDITOR="vim"
#PROFILE_END

#PROFILE=main && !(desktop || laptop)
export SOMETHING="foobarbaz"  # main but NOT desktop and NOT laptop
```

You can use Ruby operators in expressions, they are **eval**uated.  
The comment character at the start of PROFILE can be any single character,  
so if some configs use a different comment character you can still use it.  
Examples:  
* `!PROFILE=`  for ~/.Xmodmap
* `"PROFILE=`  for ~/.vimrc
  
From the terminal you can then call the script like this:
```sh
$ # Will use default profiles and files, as defined above:
$ ./profile.rb
$ # Use profile 'desktop' but NOT 'main' and NOT 'laptop' (negations not recommended) and default files:
$ ./profile.rb desktop,\!main,~laptop
$ # Use profile 'desktop' and files ~/.bashrc (alias), ~/path/to/config:
$ ./profile.rb desktop bashrc,~/path/to/config
```

## Dependencies
The only dependency is **Ruby**.  
I've developed it with Ruby version 2.4.2, but it should work with versions 2.0.0 and up.  
I haven't tested the script with Windows, but you're probably not using dotfiles if you're running Windows anyway :P

---
**Disclaimer:** I haven't been using this new version for too long yet,  
so I can't guarantee that your configs are safe :P  
The script does *overwrite* your configs, so be careful, and keep your dotfiles in a repo!

