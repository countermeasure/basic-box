usb_device_name != \
	lsblk --noheadings --raw --output rm,tran,type,path --sort path | awk '/^1 usb disk/ {d=$$4} END {print d}'

firmware_iwlwifi_deb = 'firmware-iwlwifi_20210315-3_all.deb'

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

check-usb:
	@if [ -z $(usb_device_name) ]; then \
		echo 'USB device could not be determined. Is it plugged in and mounted?'; \
		exit 1; \
	else \
		echo 'USB Device: $(usb_device_name)'; \
	fi

usb: check-usb image
	@lsblk
	@echo
	@echo "Writing to $(usb_device_name)."
	@sudo cp images/debian-11-amd64-CD-1.iso $(usb_device_name)

.PHONY: image check-usb usb
