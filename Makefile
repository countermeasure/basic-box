boot_device_name != \
	lsblk --list | grep /boot$$ | awk '{print $$1}' | head --lines 1

firmware_iwlwifi_deb = 'firmware-iwlwifi_20210315-3_all.deb'

target_device != \
	if [ $(boot_device_name) = 'nvme0n1p2' ]; then \
		echo '/dev/sda'; \
	elif [ $(boot_device_name) = 'sda1' ]; then \
		echo '/dev/sdb'; \
	else \
		echo 'unknown'; \
	fi

image:
	@./get_extra_downloads.sh
	@build-simple-cdd --conf basic.conf --verbose
	# On Debian 11, simple-cdd 0.6.8 fails to add a symlink to the first
	# firmware package (by alphabetical order), so add this symlink to the iso
	# after simple-cdd has built it.
	@xorriso \
		-boot_image isolinux patch \
		-dev images/debian-11-amd64-CD-1.iso \
		-lns \
			../pool/non-free/f/firmware-nonfree/$(firmware_iwlwifi_deb) \
			firmware/$(firmware_iwlwifi_deb)

usb: image
	@lsblk
	@echo
	@if [ $(target_device) != 'unknown' ]; then \
		echo "Writing to $(target_device)."; \
	else \
		echo 'Target device could not be determined.'; \
		echo 'Operation cancelled.'; \
		exit 1; \
	fi
	@echo
	@sudo cp images/debian-11-amd64-CD-1.iso $(target_device)

.PHONY: image usb
