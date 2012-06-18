
MULTIBOOT_VERSION := 0.6

multiboot_dir := external/multiboot
installer_dir := $(PRODUCT_OUT)/bootmenu-standalone

multiboot: \
	multiboot_clean \
	multiboot_copy_to_temp \
	multiboot_copy_to_product \
	multiboot_standalone_update


multiboot_clean:
	rm -Rf $(PRODUCT_OUT)/system/bootmenu/2nd-system
	rm -Rf $(PRODUCT_OUT)/system/bootmenu/script/2nd-system.sh
	rm -Rf $(PRODUCT_OUT)/multiboot-standalone
	rm -f $(PRODUCT_OUT)/multiboot-standalone.zip
	rm -f $(PRODUCT_OUT)/multiboot-standalone-signed.zip
	rm -Rf $(installer_dir)
	rm -f $(PRODUCT_OUT)/bootmenu-standalone.zip
	rm -f $(PRODUCT_OUT)/bootmenu-standalone-signed.zip
	
multiboot_copy_to_temp:
	# copy files to temp-directory
	mkdir $(PRODUCT_OUT)/multiboot-standalone
	cp -R $(multiboot_dir)/system $(PRODUCT_OUT)/multiboot-standalone/
	
	# clean files from gitignore-files
	find $(PRODUCT_OUT)/multiboot-standalone/ -type f -name ".gitignore" -exec rm -f {} \;
	
	# create version-file
	echo $(MULTIBOOT_VERSION) > $(PRODUCT_OUT)/multiboot-standalone/system/bootmenu/2nd-system/.version
	
multiboot_copy_to_product:
	cp -R $(PRODUCT_OUT)/multiboot-standalone/system $(PRODUCT_OUT)/
	
multiboot_standalone_update:
	# copy kernel-modules
	mkdir -p $(PRODUCT_OUT)/multiboot-standalone/system/bootmenu/2nd-system/kernel-modules
	cp device/motorola/jordan/modules/symsearch/symsearch.ko $(PRODUCT_OUT)/multiboot-standalone/system/bootmenu/2nd-system/kernel-modules/
	cp device/motorola/jordan/modules/multiboot/multiboot.ko $(PRODUCT_OUT)/multiboot-standalone/system/bootmenu/2nd-system/kernel-modules/
	
	# copy updater-script
	cp -R $(multiboot_dir)/META-INF $(PRODUCT_OUT)/multiboot-standalone/
	mv $(PRODUCT_OUT)/multiboot-standalone/META-INF/com/google/android/updater-script $(PRODUCT_OUT)/multiboot-standalone/META-INF/com/google/android/updater-script.tmp
	sed -r 's/\{VERSION\}/$(MULTIBOOT_VERSION)/' $(PRODUCT_OUT)/multiboot-standalone/META-INF/com/google/android/updater-script.tmp > $(PRODUCT_OUT)/multiboot-standalone/META-INF/com/google/android/updater-script
	rm $(PRODUCT_OUT)/multiboot-standalone/META-INF/com/google/android/updater-script.tmp
	
	# build zip
	cd $(PRODUCT_OUT)/multiboot-standalone && zip -r ../multiboot-standalone.zip *
	
	# sign zip
	java -jar $(HOST_OUT_JAVA_LIBRARIES)/signapk.jar -w build/target/product/security/testkey.x509.pem build/target/product/security/testkey.pk8 $(PRODUCT_OUT)/multiboot-standalone.zip $(PRODUCT_OUT)/multiboot-standalone-signed.zip
	
	
bootmenu_standalone_update: \
	multiboot \
	bootmenu_standalone_copy_files
	
bootmenu_standalone_copy_files:
	mkdir -p $(installer_dir)/system/bootmenu
	
	# copy base-bootmenu
	cp -R $(multiboot_dir)/bootmenu-base/* $(installer_dir)/system/bootmenu/
	
	# copy multiboot-files
	cp -Rf $(PRODUCT_OUT)/multiboot-standalone/system $(installer_dir)/
	
	# copy bootmenu-binary
	mkdir -p $(installer_dir)/system/bin
	cp $(PRODUCT_OUT)/system/bin/bootmenu $(installer_dir)/system/bin/bootmenu
	cp $(installer_dir)/system/bootmenu/binary/logwrapper.bin $(installer_dir)/system/bin/logwrapper.bin
	
	# copy update-script
	mkdir -p $(installer_dir)/META-INF/com/google/android
	cp $(multiboot_dir)/META-INF/com/google/android/update-binary $(installer_dir)/META-INF/com/google/android/update-binary
	cp $(multiboot_dir)/updater-script-bootmenu $(installer_dir)/META-INF/com/google/android/updater-script
	
	# build zip
	cd $(installer_dir) && zip -r ../bootmenu-standalone.zip *
	
	# sign zip
	java -jar $(HOST_OUT_JAVA_LIBRARIES)/signapk.jar -w build/target/product/security/testkey.x509.pem build/target/product/security/testkey.pk8 $(PRODUCT_OUT)/bootmenu-standalone.zip $(PRODUCT_OUT)/bootmenu-standalone-signed.zip
	