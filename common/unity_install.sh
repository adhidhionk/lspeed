#
# Installing manager from $MODPATH/
#
unzip -o "$ZIPFILE" 'app/*' -d /data/local/tmp >&2

apkDir="/data/local/tmp/app"

installApk() {

	filelist=$(ls $1)

	for file in $filelist; do

		extension="${file##*.}"

		if [ "$extension" = "apk" ]; then
			echo "- Installing ""$file""..."
			pm install -r "$1/$file"
			
			echo "- Successfully installed $file"
		else
			echo "- Error: ""$file" "is not an apk file."
		fi
	done

}
  
installApk $apkDir
rm -rf $apkDir
