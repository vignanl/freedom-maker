#! /usr/bin/make

# Where to fetch packages
MIRROR = http://http.debian.net/debian

# armel amd64 i386
ARCHITECTURE = armel
# dreamplug guruplug virtualbox raspberry(pi)
MACHINE = dreamplug
# card usb hdd
DESTINATION = card
BUILD = $(MACHINE)-$(ARCHITECTURE)-$(DESTINATION)
TODAY := `date +%Y-%m-%d`
NAME = build/freedombox-unstable_$(TODAY)_$(BUILD)
WEEKLY_DIR = torrent/freedombox-unstable_$(TODAY)
IMAGE = $(NAME).img
ARCHIVE = $(NAME).tar.bz2
SIGNATURE = $(ARCHIVE).sig
SUITE = sid
SOURCE = false
OWNER = 1000
TAR = tar --checkpoint=1000 --checkpoint-action=dot -cjvf
SIGN = -gpg --output $(SIGNATURE) --detach-sig $(ARCHIVE)

# Using taskset to pin build process to single core. This is a
# workaround for a qemu-user-static issue that causes builds to
# hang. (See Debian bug #769983 for details.)
MAKE_IMAGE = ARCHITECTURE=$(ARCHITECTURE) DESTINATION=$(DESTINATION) \
    MACHINE=$(MACHINE) SOURCE=$(SOURCE) MIRROR=$(MIRROR) SUITE=$(SUITE) OWNER=$(OWNER) \
    taskset 0x01 bin/mk_freedombox_image $(NAME)

# build DreamPlug USB or SD card image
dreamplug: prep
	$(eval ARCHITECTURE = armel)
	$(eval MACHINE = dreamplug)
	$(eval DESTINATION = card)
	$(MAKE_IMAGE)
	$(TAR) $(ARCHIVE) $(IMAGE)
	@echo ""
	$(SIGN)
	@echo "Build complete."

# build Raspberry Pi SD card image
raspberry: prep
	$(eval ARCHITECTURE = armel)
	$(eval MACHINE = raspberry)
	$(eval DESTINATION = card)
	$(MAKE_IMAGE)
	$(TAR) $(ARCHIVE) $(IMAGE)
	@echo ""
	$(SIGN)
	@echo "Build complete."

# build Beaglebone SD card image
beaglebone: prep
	$(eval ARCHITECTURE = armhf)
	$(eval MACHINE = beaglebone)
	$(eval DESTINATION = card)
	$(MAKE_IMAGE)
	$(TAR) $(ARCHIVE) $(IMAGE)
	@echo ""
	$(SIGN)
	@echo "Build complete."

# build a virtualbox image
virtualbox: prep
	$(eval ARCHITECTURE = i386)
	$(eval MACHINE = virtualbox)
	$(eval DESTINATION = hdd)
	$(MAKE_IMAGE)
# Convert image to vdi hard drive
	VBoxManage convertdd $(NAME).img $(NAME).vdi
	$(TAR) $(ARCHIVE) $(NAME).vdi
	@echo ""
	$(SIGN)
	@echo "Build complete."

vendor/vmdebootstrap/vmdebootstrap: vendor-patches/vmdebootstrap/*.patch
	bin/fetch-new-vmdebootstrap

prep: vendor/vmdebootstrap/vmdebootstrap
	mkdir -p build

clean:
	-rm -f build/freedombox.log
	-rm -f $(IMAGE) $(ARCHIVE)

distclean: clean
	sudo rm -rf build
