# feedpage

Dirt simple RSS feed reader script. Download feed content, build a static html page.


## Setup

* Install a few ruby gems: `daemons`, `feedjira`. Feedjira is a bit of a bear and will have some dependencies.

* Set your config directory. Edit the `feedpage` script and set the `base_path` variable to where you want to keep your config file. I use `~/.config/feedpage`.

* Copy the config file. For my setup:
```
cd ~/.config
mkdir feedpage
cp ~/bin/feedpage/example_config/config.yaml feedpage #I cloned feedpage to ~/bin
```

* edit the config, copy the needed example files to where you want them.

* customize!
  * Add your crap to url_list.yaml
  * Modify homepage.erb to your liking
  * edit `recent_entries_proc` in `feedpage` or make a new proc in to change what content is displayed

## Run

I have feedpage run as a daemon, and update my rss homepage every 45 minutes. I have this line in `.xinitrc`: `feedpage --daemon 45 --log`
