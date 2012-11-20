# Spotify automatic installer for openSUSE

This script avoids the need to illegally redistribute Spotify binaries
by downloading the Linux client `.deb` from
[repository.spotify.com](http://repository.spotify.com/pool/non-free/s/spotify/),
converting it to `.rpm` format, and then installing it along with some
evil hacks to provide the necessary libraries where Spotify expects
them to be.

Currently only openSUSE 12.2 is supported.  Patches to support others
(e.g. [Factory](http://en.opensuse.org/Portal:Factory)) are very
welcome!

The vast majority of the credit and thanks for this script
go to [Armin](http://community.spotify.com/t5/user/viewprofilepage/user-id/190504) on the Spotify community forums, who wrote the
[original version](http://community.spotify.com/t5/Desktop-Linux/Segfault-on-opensuse-12-2/m-p/161048/highlight/true#M1331).
I have just added a small amount of polish.

Thanks also to the relatively anonymous Spotify employees who donated
free time to make the Linux client available.  *No* thanks go to
Spotify middle/upper management for consistently refusing to invest
the small amount of resources required to even acknowledge their
Linux-based customers, let alone support them.

## How to use

1. [Download the script](https://raw.github.com/aspiers/opensuse-spotify-installer/master/install-spotify.sh)
2. *(optional)* Read it to make sure it's not going to [pwn](http://en.wikipedia.org/wiki/Pwn) your computer.
3. Make it executable, e.g. from a terminal, type `chmod +x install-spotify.sh`
4. Run it as the `root` user, e.g. from a terminal type `sudo ./install-spotify`, or `su`, enter the root password, and then `./install-spotify`

## A alternative way

`alien` is a convertor instead of a build tool. It's not the case like codecs that a flac convertor can make the same quality from wav as a flac recorder.

Every package has an orientation, eg: a `deb` is optimized for Debian system, which has a great many differences (everywhere) against RPM system. eg: we put `python modules` in `/usr/lib/python-2.7/dist-packages` in Debian, but actually in openSUSE they should be placed under `/usr/lib/python-2.7/site-packages`. It's out of `alien`'s capacity to do such a path convertion.

In short, `alien` is enough for personl use (of couse you can't be compulsive or a neat freak), but isn't enough for distribution (That's why openSUSE never just convert deb to make a distribution). like `checkinstall`, they both can't make **pure** packages.

Under `~/spec` there's a shell script that generate a standard RPM under your `$HOME` directory (`/home/username`). Although there're still some obstacles to overcome, Spotify is now managable as all other packages under openSUSE. You can trace dependencies, remove in YaST and zypper, and it won't leave you a dirty `/usr`, everything is traced by RPM system. 

### Shortcomings for now (maybe forever)

* can't install using zypper/YaST/rpm painlessly.

it's because we do the linking for `/usr/lib(64)/libnss.so.1d` stuff, which never exist in openSUSE. but Linux shared library finding machanism will try to find dependencies for every library (softlink or not) under `/usr/lib(64)`, which will cause a unresolvable error. but you can `sudo rpm -ivh --nodeps spotify-*.rpm` or `sudo zypper install --no-refresh --force-resolution spotify-*.rpm`.

## License

I certainly cannot claim any copyright on this, since it is just
Armin's version with a few tweaks applied.  He posted it without any
copyright notice, so I unless I hear otherwise I'll assume it's in the
public domain.

## Support, bugs, development etc.

Please check the [issue tracker](https://github.com/aspiers/opensuse-spotify-installer/issues)
for known issues, and if yours is not there, please submit it.
I can't guarantee that I'll be able to fix it, or even respond,
but I'll try, and even if I can't help, this is github, so anyone else
can potentially help you out too.

Even better, if you know how to fix a problem with the script, please
[fork this repository](https://github.com/aspiers/opensuse-spotify-installer/fork_select), commit
your fix, and then send me a [pull request](https://help.github.com/articles/using-pull-requests)!

## Why is this script here on github?

I hope it's kind of obvious from the above.  But since you
got me on the soapbox ...

`<rant length="very long">`

Web forums breed endless technological misery.  They are bloated,
slow, clunky quagmires which result in long meandering threads of
unstructured communication.  Trying to install Spotify after every
distribution upgrade typically involves the following steps:

1. google for something like 'spotify opensuse 12.2'
2. wade through a *huge* number of hits from web forum threads or blog post or wiki page,
   many of which are too old to be useful
3. select the most promising looking hit
4. wade through a long forum thread or web page
5. re-live other people's trial-and-error experiences
6. realise that most people on this thread don't really know what they're doing
   and no-one fully figured it out
7. repeat steps 3--6 a few times
8. observe that every man and his dog has come up with their own
   partial solution which is similar but slightly different to the next
   person's, due to various gotchas which apply in some cases but not others
9. scream "I don't care, I just want the ****ing thing to work!" a few times
10. mentally recombine several different nuggets of information
11. experiment a bit

... and eventually maybe you get it to work.  If you're really lucky
Spotify might only segfault occasionally!

(If I was [rms](http://en.wikipedia.org/wiki/Richard_Stallman), now
would be the time to point out that this is inevitable karma for
trying to use [freedom-denying software](http://www.gnu.org/philosophy/);
sadly I do not possess as much integrity as him though.)

I've been working closely with Linux since 1995 and even with a lot of
experience I find process this painful and frustrating every time.  So
I can't imagine how annoyed Linux newbies must get when they want to
do something as conceptually simple as installing Spotify on an
rpm-based distro, and find that they have to struggle through this
crap.  It flies against *all* conventional wisdom regarding best
practices in software development and deployment.

Going through this yet again after this latest upgrade to openSUSE
12.2 was the straw that broke the camel's back (Fedora 16 was the
penultimate straw...)  So let's take a stand.  We can and will do
better!  Barring an unexpected miracle from Spotify management where
they suddenly decide to stop ignoring their Linux user base, the
solution is relatively simple.  We just need to treat the problem with
respect, i.e. just like any other free or open source software project
out there - it deserves standard best practices.  That means an
automated deployment mechanism which is tracked properly using
decentralized version control, a bug tracker, and a collaborative
platform which allows anyone to chip in and help in a *structured*
fashion.  Fortunately github is totally mind-bendingly awesome at
this, and free!  So let's use it!

`</rant>`

If we want to get fancy, we might even think about packaging up
the installer into [a community repository](http://opensuse-community.org/Repositories)
to get closer to that [one-click install](http://en.opensuse.org/openSUSE:One_Click_Install)
dream ...
