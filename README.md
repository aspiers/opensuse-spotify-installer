# Spotify automatic installer for openSUSE

This script avoids the need to illegally redistribute Spotify binaries
by downloading the Linux client `.deb` from
[repository.spotify.com](http://repository.spotify.com/pool/non-free/s/spotify/),
converting it to `.rpm` format, and then installing it along with some
evil hacks to provide the necessary libraries where Spotify expects
them to be.

Currently openSUSE 12.2 and 12.3 are supported.  Patches to support
others (e.g. [Factory](http://en.opensuse.org/Portal:Factory)) are
very welcome!

## News

2013-06-26: Squashed myriads of bugs. Now runs building 0.9.1 on 12.1 and 12.3.

2013-06-26: This should really be merged upstream, but this process has stalled
ATM. Until merged, I'll try to keep this fork alive.

## How to use

This fork is not available on Packman. To use::

    $ repo='https://raw.github.com/leamas/opensuse-spotify-installer/master'
    $ wget $repo/install-spotify.sh
    $ bash install-spotify.sh
The installer uses `sudo` for operations which require root privileges, so
you may be prompted for a password during the install.

## Support, bugs, development etc.

Development lives at the home page:

* [https://github.com/leamas/opensuse-spotify-installer](https://github.com/leamas/opensuse-spotify-installer)

Please check the [issue tracker](https://github.com/leamas/opensuse-spotify-installer/issues)
for known issues, and if yours is not there, please submit it.
I can't guarantee that I'll be able to fix it, or even respond,
but I'll try, and even if I can't help, this is github, so anyone else
can potentially help you out too.

Even better, if you know how to fix a problem with the script, please
[fork this repository](https://github.com/leamas/opensuse-spotify-installer/fork_select),
commit your fix (here are [some hints](http://blog.adamspiers.org/2012/11/10/7-principles-for-contributing-patches-to-software-projects/)),
and then send me a [pull request](https://help.github.com/articles/using-pull-requests)!

## Why not just use the new web-based player?

There's a new browser-based Spotify player accessible via
[https://play.spotify.com/](https://play.spotify.com/) or
[https://apps.facebook.com/get-spotify/](https://apps.facebook.com/get-spotify/).

However, [it does not seem to be generally available yet](http://howto.cnet.com/8301-11310_39-57551372-285/enable-spotifys-web-player-right-now/), and [is missing many features](http://community.spotify.com/t5/Desktop-Linux/ANNOUNCE-Spotify-0-8-4-for-GNU-Linux/m-p/204364/highlight/true#M1687) compared to the standalone Linux client.

## Credits and thanks

Of course, this is a fork of aspier's installer and I owe him credit for
most of this code.

aspiers wrote: this is not all my own work.  The following people deserve credit and
thanks for some of the code in this installer:

* [Armin](http://community.spotify.com/t5/user/viewprofilepage/user-id/190504) on the Spotify community forums, who wrote the
[original version](http://community.spotify.com/t5/Desktop-Linux/Segfault-on-opensuse-12-2/m-p/161048/highlight/true#M1331).
* [Marguerite Su](https://github.com/marguerite) who provided an initial `.spec` file and helped eventually convince me it was worth moving away from `alien`.

Huge thanks also to the relatively anonymous Spotify employees such as
[parbo](http://community.spotify.com/t5/user/viewprofilepage/user-id/23361)
who have been donating some of their free time to make the Linux
client available.  *No* thanks go to Spotify middle/upper management
for consistently refusing to invest the small amount of resources
required to even acknowledge their Linux-based customers, let alone
support them.

## License

This installer does *not* contain any material whatsoever copyrighted
by Spotify:

*   `install-spotify.sh` is a derivative of Armin's original version which
    he posted it without any copyright notice, so I unless I hear
    otherwise I'll assume it's in the public domain.
*   `spotify-client.spec` is a derivative of Marguerite Su's original
    `spotify.spec`, the header of which seems to imply that it's
    MIT-licensed (since the pristine package the header refers to is
    either Spotify or non-existent, depending on how you look at it).
*   `spotify-installer.spec` is all my work.

Therefore I think it's fair to say the overall license is MIT (i.e.
less ambiguously, the X11 license).
