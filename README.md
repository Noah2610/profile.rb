# ProfileRB v2
by Noah Rosenzweig

---

## Table Of Contents
* [Description](#description)
* [Installation](#installation)
* [Configuration](#configuration)
  * [Quick Summary](#quick-summary)
* [Usage](#usage)
  * [Default Syntax](#default-syntax)
  * [Command-Line Usage](#command-line-usage)
    * [Synopsis](#synopsis)
    * [Examples](#examples)

---

## Description
This is the second version of my small profiling script written in Ruby.  
It's main use is for configs / dotfiles.  
If you use multiple machines which share the same configs but with differences between configs then this script could be useful.  
  
The base concept of this script is to have markers in your configs (as comments)  
that tell the script which profile this config snippet is associated to.  
When the script is executed, it will then either **comment out** or **uncomment** those snippets,  
according to what profile you want to use.

## Installation
The only dependency is **Ruby**.  
It should work with versions 2.0.0 and up.  
I haven't tested the script with Windows, but you're probably not using  
dotfiles if you're running Windows anyway.
  
As long as Ruby is installed, you should have no issues using this script  
after cloning the repo:
```
$ git clone https://github.com/Noah2610/profile.rb.git ./ProfileRB; cd ./ProfileRB/
```

## Configuration
The script checks for a YAML config file in the following locations and order:
* `~/.config/profilerb/config.yml`
* `~/.profilerb.yml`
* `<PROJECT-ROOT>/config.yml`
  
The default config.yml file (`./config.yml`) is pretty well documented  
in form of comments inside the file itself, so check it out for a more  
detailed explanation and documentation of the config syntax.

### Quick Summary
I'll give a quick explanation here:  
  
The config file has four sections:
* `file_aliases`  
  In here you can associate strings with filepaths, so you  
  don't need to type the whole path out in the `files` section,  
  and can easily activate and deactivate them.
* `files`  
	Here are the files that you want to have processed by default.  
	You can use `file_aliases` here.
* `hostname_profiles`  
  Here you can associate a list of profiles to use by default  
	according to the machine's hostname.
* `keywords`  
  In here the syntax you use inside the files is defined.  
  The default config is configured to use the syntax described below under __Default Syntax__.

## Usage
### Default Syntax
By default you can use syntax like this in the files you want to have _profiled_ (your dotfiles):
```sh
#PROFILE = desktop && main
set -o vi    # For profiles desktop AND main, only effects next line (this line)

#PROFILE_START = laptop || default
# Everything between PROFILE_START and PROFILE_END is effected
export PATH="$HOME/bin:$PATH"
export EDITOR="vim"
#PROFILE_END

#PROFILE = main && !(desktop || laptop)
export SOMETHING="foobarbaz"  # main but NOT desktop and NOT laptop
```
The syntax is defined as _Regular Expressions_ in the config file.  
  
You can use Ruby operators in expressions, they are <u>eval</u>uated.  
  

### Command-Line Usage
#### Synopsis
```
./profile.rb [PROFILE1,PROFILE2,... [FILE1,FILE2,...]]
```
#### Examples
```sh
$ # Will use default profiles and files, as defined in your config:
$ ./profile.rb
$ # Use profile 'desktop' but NOT 'main' and NOT 'laptop' (negations not recommended) and default files:
$ ./profile.rb desktop,\!main,~laptop
$ # Use profile 'desktop' and files ~/.bashrc (alias), ~/path/to/config:
$ ./profile.rb desktop bashrc,~/path/to/config
```

I plan to expand the CL usage with some options using my Ruby [Argument Parser](https://github.com/Noah2610/ArgumentParser).

