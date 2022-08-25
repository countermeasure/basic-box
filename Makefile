firmware_iwlwifi_deb = 'firmware-iwlwifi_20210315-3_all.deb'

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

sudo:
	@sudo -v

usb: check sudo image
	@sudo cp images/debian-11-amd64-CD-1.iso $(target_device)

.PHONY: check image sudo usb
