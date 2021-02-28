# Debian deep freezer
Deep freeze your Debian-based Linux with wrapped Lethe. All changes made to frozen system are reverted after reboot. Changes can be made in dedicated grub entry.

## About

This tool uses old program called `Lethe`. It wrapps some things so that this old fella runs on modern Debian-based Linuxes (such as Ubuntu).

## Usage

To freeze your Linux, simply run commands listed below:
```bash
git clone https://github.com/TheArqsz/deep-freezer.git && \
cd deep-freezer && \
chmod +x deep-freezer.sh && \
./deep-freezer.sh
```

To unfreeze your system, run:
```bash
./deep-freezer.sh --unfreeze
```
or 
```bash
./deep-freezer.sh -u
```

Other parameters:
```bash
./deep-freezer.sh --no-color # do not use colors in output
./deep-freezer.sh --verbose # verbose output
./deep-freezer.sh --help # show help
```

## Grub entries

Script creates two grub entries:
- First with plain name of distribution (e.g. Debian or Ubuntu) which is freezed by Lethe - changes made here, are not persistent
- Second with name `Persistent (not Lethe-freezed) distribution-name` - changes made here are persistent and visible for previous entry

## Licensing

All rights for `Lethe` go to its authors. It is licensed under GPL license. Files can be found [here](https://sourceforge.net/projects/lethe/). Copyright notice for Lethe Debian package may be found [here](https://sourceforge.net/p/lethe/git/ci/master/tree/tags/lethe-0.34/debian/copyright).

I am the author only for wrapper that automates deep freeze. It may be shared under GPL license (see [LICENSE](LICENSE)).