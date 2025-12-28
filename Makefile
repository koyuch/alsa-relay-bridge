# Makefile for alsa-relay-bridge
# Used by debian/rules during package build

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
SYSTEMDDIR = /lib/systemd/system
SHAREDIR = /usr/share/alsa-relay-bridge
DOCDIR = /usr/share/doc/alsa-relay-bridge

.PHONY: all install clean

all:
	@echo "Nothing to build. Use 'make install' to install."

install:
	# Create directories
	install -d $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(SYSTEMDDIR)
	install -d $(DESTDIR)$(SHAREDIR)
	install -d $(DESTDIR)$(DOCDIR)
	
	# Install daemon script (keep original name, will be renamed by postinst if needed)
	install -m 755 relay_volume.py $(DESTDIR)$(BINDIR)/
	
	# Install systemd service
	install -m 644 alsa-relay-volume.service $(DESTDIR)$(SYSTEMDDIR)/
	
	# Install ALSA configuration reference
	install -m 644 asound.conf $(DESTDIR)$(SHAREDIR)/
	
	# Install documentation
	install -m 644 README.md $(DESTDIR)$(DOCDIR)/
	install -m 644 INSTALL.md $(DESTDIR)$(DOCDIR)/

clean:
	@echo "Nothing to clean."
