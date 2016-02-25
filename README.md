Recently I've noticed that I should update README file or it might cause confusions.
So here it is.

# Spotify automatic installer for openSUSE

This is a modified version of [Adam Spiers' install script](https://github.com/aspiers/opensuse-spotify-installer).

It works mostly like the original one: download `.deb` package then repack it to `.rpm` file for RPM-based system to install.
I've add some scripts which make it able to get latest version online, you might have to install `curl` or it may fails.

It only tested on Tumbleweed, but I think Leap can also work.

## How to use

The package on [PackMan](http://packman.links2linux.org/) is the unmaintained version, so you might consider not using it.

If you're familiar to git, just checkout this repository then run `install-spotify.sh`.

Or you can manually download `install-spotify.sh` and `spotify-client.spec` to same folder then run it.

1. Download the [`install-spotify.sh`](https://raw.github.com/cornguo/opensuse-spotify-installer/master/install-spotify.sh) script
2. Download [`spotify-client.spec`](https://raw.github.com/cornguo/opensuse-spotify-installer/master/spotify-client.spec) and place it with the script
3. *(optional)* Read the source to make sure it's not going to [pwn](http://en.wikipedia.org/wiki/Pwn) your computer.
4. Make the script executable, e.g. from a terminal, type `chmod +x install-spotify.sh`
5. Run it as a non-root user, e.g. from a terminal type `./install-spotify.sh`

The installer uses `sudo` for operations which require root privileges, so
you may be prompted for a password during the install.

## Bug?

When something's wrong, please feel free to create an issue at [issue tracker](https://github.com/cornguo/opensuse-spotify-installer/issues).

And it is always welcome to fork this repository and make your own mods. :)

## Credits and thanks

Thanks to [Adam Spiers](https://github.com/aspiers) who created this handy but helpful script.

Following is the original text:

> This is not all my own work.  The following people deserve credit and
> thanks for some of the code in this installer:
>
> * [Armin](http://community.spotify.com/t5/user/viewprofilepage/user-id/190504) on the Spotify community forums, who wrote the
> [original version](http://community.spotify.com/t5/Desktop-Linux/Segfault-on-opensuse-12-2/m-p/161048/highlight/true#M1331).
> * [Marguerite Su](https://github.com/marguerite) who provided an initial `.spec` file and helped eventually convince me it was worth moving away from `alien`.
>
> Huge thanks also to the relatively anonymous Spotify employees such as
> [parbo](http://community.spotify.com/t5/user/viewprofilepage/user-id/23361)
> who have been donating some of their free time to make the Linux
> client available.  *No* thanks go to Spotify middle/upper management
> for consistently refusing to invest the small amount of resources
> required to even acknowledge their Linux-based customers, let alone
> support them.

## License

This script is a derivative of [Adam Spiers' work](https://github.com/aspiers/opensuse-spotify-installer),
and it will use same X11 Licence.

Following is the original licence text:

> This installer does *not* contain any material whatsoever copyrighted
> by Spotify:
>
> *   `install-spotify.sh` is a derivative of Armin's original version which
>     he posted it without any copyright notice, so I unless I hear
>     otherwise I'll assume it's in the public domain.
> *   `spotify-client.spec` is a derivative of Marguerite Su's original
>     `spotify.spec`, the header of which seems to imply that it's
>     MIT-licensed (since the pristine package the header refers to is
>     either Spotify or non-existent, depending on how you look at it).
> *   `spotify-installer.spec` is all my work.
> Therefore I think it's fair to say the overall license is MIT (i.e.
> less ambiguously, the X11 license).

## Why is this script here on github?

Because I need it. :p
