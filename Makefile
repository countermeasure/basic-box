branch != git rev-parse --abbrev-ref HEAD

commit != git rev-parse --short HEAD

date != date +"%d %b %Y"

target_device != lsblk --output tran,path | awk '$$1 == "usb" { print $$2 }'

target_device_description != \
	 lsblk --output tran,size,model,path | \
	 awk '$$1 == "usb" { print $$2 " " $$3 " (device " $$4 ")" }'

usb_drive_count != lsblk --output tran | grep '^usb$$' | wc --lines

check:
	@echo
	@if [ $(usb_drive_count) -eq 0 ]; then \
		echo 'There was no USB drive found.'; \
		echo; \
		echo 'Connect a USB drive.'; \
		exit 1; \
	elif [ $(usb_drive_count) -gt 1 ]; then \
		echo "There were $(usb_drive_count) USB drives found."; \
		echo; \
		echo 'Make sure that only one USB drive is connected.'; \
		exit 1; \
	fi
	@echo "The $(target_device_description) will become an installer."
	@echo
	@echo 'All data on that device will be lost.'
	@echo

image: init
	@./get_firmware_and_packages.sh
	@# Make a file with build information about the installer.
	@mkdir --parents build
	@echo "Date:   $(date)" > build/build.txt
	@echo "Commit: $(commit)" >> build/build.txt
	@echo "Branch: $(branch)" >> build/build.txt
	@# Build the image.
	@build-simple-cdd --conf basic.conf --verbose
	# Add firmware to the installer image which has just been built. There
	# doesn't seem to be a good way to do this with simple-cdd directly.
	@mkdir -p tmp/firmware
	@tar \
		--extract \
		--file firmware/firmware.tar.gz \
		--directory tmp/firmware
	@xorriso \
		-boot_image isolinux patch \
		-dev images/debian-13-amd64-CD-1.iso \
		-map tmp/firmware firmware
	@rm -rf tmp/firmware

init:
	# TODO: Are jq and wget already installed in Trixie?
	@required_packages="jq libnotify-bin make simple-cdd wget"; \
	for package in $$required_packages; do \
		if ! dpkg -s $$package >/dev/null 2>&1; then \
			if [ $$package = 'simple-cdd' ]; then \
				# The ``simple-cdd`` package for Debian 13, which is version 0.6.9, is
				# broken. Instead, install version 0.6.10. \
				# TODO: Shorten the next two lines. \
				wget https://deb.debian.org/debian/pool/main/s/simple-cdd/simple-cdd_0.6.10_all.deb; \
				wget https://deb.debian.org/debian/pool/main/s/simple-cdd/python3-simple-cdd_0.6.10_all.deb; \
				sudo apt install ./simple-cdd_0.6.10_all.deb; \
				sudo apt install ./python3-simple-cdd_0.6.10_all.deb; \
			else \
				sudo apt install --yes $$package; \
			fi; \
			echo "Installed $$package"; \
		fi; \
	done

sudo:
	@sudo -v

symlinks:
	@./create_symlinks.sh

usb: check sudo init image
	@echo "Writing the image to the $(target_device_description)..."
	@# If sync is not called, eject will run before the copy completes.
	@sudo cp images/debian-13-amd64-CD-1.iso $(target_device); sync
	@sudo eject $(target_device)
	@notify-send \
		'Installer created' \
		'The USB drive can be removed.' \
		--icon \
		/usr/share/icons/Adwaita/scalable/devices/media-removable-symbolic.svg

vm: init
	# TODO: Add qemu installer to this target or the init target. Maybe a "qemu"
	# target? Or maybe just this target.
	# @./get_firmware_and_packages.sh
	@qemu-img create -f qcow2 tmp/mirror/qemu-test.hd.img 12G
	@build-simple-cdd \
		--conf basic.conf \
		--debian-mirror http://localhost:9999/debian \
		--qemu \
		--verbose

.PHONY: check image init sudo symlinks usb vm
