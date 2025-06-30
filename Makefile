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

image:
	@./get_firmware_and_packages.sh
	@# Make a file with build information about the installer.
	# TODO: Condense this into a heredoc, and make it json.
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
		-dev images/debian-12-amd64-CD-1.iso \
		-map tmp/firmware firmware
	@rm -rf tmp/firmware

sudo:
	@sudo -v

symlinks:
	@./create_symlinks.sh

usb: check sudo image
	@echo "Writing the image to the $(target_device_description)..."
	@# If sync is not called, eject will run before the copy completes.
	@sudo cp images/debian-12-amd64-CD-1.iso $(target_device); sync
	@sudo eject $(target_device)
	@notify-send \
		'Installer created' \
		'The USB drive can be removed.' \
		--icon \
		/usr/share/icons/Adwaita/scalable/devices/media-removable-symbolic.svg

.PHONY: check image sudo symlinks usb
