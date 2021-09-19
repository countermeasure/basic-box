image:
	@build-simple-cdd --conf basic.conf --verbose

usb: image
	@sudo cp images/debian-10-amd64-CD-1.iso /dev/sdb

.PHONY: image usb
