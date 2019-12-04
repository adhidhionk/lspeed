# Removing L Speed manager from /system if exists
appPath1="/system/app/com.paget96.lspeedmanager.apk"
appPath2="/system/priv-app/com.paget96.lspeedmanager.apk"
appPath3="/system/app/com.paget96.lspeedmanager"
appPath4="/system/priv-app/com.paget96.lspeedmanager"

if [ -e $appPath1 ]; then
	rm -rf $appPath1;
	echo "Removing L Speed manager from $appPath1"
	
elif [ -e $appPath2 ]; then
	rm -rf $appPath2;
	echo "Removing L Speed manager from $appPath2"
	
elif [ -e $appPath3 ]; then
	rm -rf $appPath3;
	echo "Removing L Speed manager from $appPath3"
	
elif [ -e $appPath4 ]; then
	rm -rf $appPath4;
	echo "Removing L Speed manager from $appPath4"
fi

#
# Installing manager from $MODPATH/app/
#
apkDir="$MODPATH/app/"
  cd $apkDir || exit

installApk() {

	cd $apkDir || exit

	filelist=$(ls "$1")

	for file in $filelist; do

		extension="${file##*.}"

		if [ "$extension" = "apk" ]; then

			echo "Installing ""$file""..."
			#cp -r -f  /sdcard/apks/*.apk /data/local/tmp/
			pm install -r -f -d "$file"
			
			echo "Successfully installed $file"
		else
			echo "Error: ""$file" "is not an apk file."
		fi
	done

}
  
installApk $apkDir
rm -rf $apkDir
