# Spotify RPM Spec file for openSUSE, Fedora, Mandriva, Mageia.

Once I used to create Spotify RPMs directly on openSuSE Build Service, but it was banned and actually violated Spotify License.

Then I saw [Fedora Mumble RPMs](http://mumble.knobgoblin.org.uk/), which is a great idea for sharing such repackaged commercial packages. it's benefit is listed on their sites, so as ours.

The Principle of Mumble RPMs is to license RPM specfiles under an open source agreement, and only ships the `.nosrc.rpm` or `.spec` without commercial binaries. That package/file is free and open source. But you have to fetch the commercial bits to rebuild and use for your own purpose.(not redistributable for the output real RPMs, but you still can spread the .nosrc.rpm or specfile to others and tell them how to rebuild/build for a real RPM)

Anyway, it's for those alien haters.

# Easy script

Download [~/spotify-rpm-generator.sh](https://raw.github.com/aspiers/opensuse-spotify-installer/master/spec/spotify-rpm-generator.sh) and run.

# Build for yourself

You need `rpmbuild` package from your system.

Then find the hiearchy like `/usr/src/packages`:


		-- BUILD
		-- BUILDROOT
		-- RPMS
   			-- i586
   			-- x86_64
   			-- noarch
		-- SOURCES
		-- SPECS
		-- SRPMS

It may be under your `$HOME/rpmbuild` (for openSUSE). Or you can just use `/usr/src/packages` but it may require root permission.

Download spotify deb from [http://repository.spotify.com/pool/non-free/s/spotify](http://repository.spotify.com/pool/non-free/s/spotify) and put it under `SOURCES`.

Download this spec and put it under `SPECS`.

It has no actual dependencies, so we just start building:

		cd SPECS
		rpmbuild -ba spotify.spec

Generated packages will be under RPMS/x86_64 or RPMS/i586 directory.

Use:

		sudo rpm -ivh --nodeps *.rpm

or

		sudo zypper install --no-refresh --force-resolution *.rpm

to install it. (`--nodeps` or `--force-resolution` is very important!)

You need these runtime dependencies: 

* openSUSE: mozilla-nss, mozilla-nspr, libopenssl1_0_0 
* Fedora: nss, nspr, openssl(>= 1.0.1) 
* Mandriva and Mageia: libnss3, libnspr4, libssl1.0.0

to get it running. 

Have a lot of fun!

![](https://raw.github.com/marguerite/opensuse-spotify-installer/master/spec/spotify-screenshot.png)

