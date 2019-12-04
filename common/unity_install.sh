
#
# Installing manager from $MODPATH/
#
unzip -o "$ZIPFILE" 'app/*' -d $MODPATH/ >&2

apkDir="$MODPATH/app/"
  cd $apkDir || exit

installApk() {

	cd $apkDir || exit

	filelist=$(ls "$1")

	for file in $filelist; do

		extension="${file##*.}"

		if [ "$extension" = "apk" ]; then

			echo "- Installing ""$file""..."
			#cp -r -f  /sdcard/apks/*.apk /data/local/tmp/
			pm install -r -f -d "$file"
			
			echo "- Successfully installed $file"
		else
			echo "- Error: ""$file" "is not an apk file."
		fi
	done

}
  
installApk $apkDir
rm -rf $apkDir
