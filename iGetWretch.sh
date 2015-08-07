#iGetWretch V0.35b
#!/bin/bash
CD="./CocoaDialog.app/Contents/MacOS/CocoaDialog"
rv=`$1/Contents/Resources/$CD standard-inputbox --title "Wretch Album Address" --no-newline \\
    --informative-text "Enter Album address"` 
IN_URL=`echo $rv | sed 's/^.*1\ //g'`
USER=`echo $IN_URL | sed  's/^.*id=//g' | sed 's/&book=.*$//g'`
ALBUM=`echo $IN_URL | sed  's/^.*book=//g'`
echo "Downloading html source code..."
mkdir ~/Wretch_Album
cd ~/Wretch_Album
mkdir ./$USER"_"$ALBUM
cd ./$USER"_"$ALBUM
curl -e "http://www.wretch.cc" -o wretch_tmp.html $IN_URL
PIC_URL=`grep "&p=0\"" ./wretch_tmp.html |\
sed 's/^.*a href=".//g' | sed 's/">.*$//g'`
NEXT_PAGE=`echo "http://www.wretch.cc/album"$PIC_URL`
#echo $NEXT_PAGE
F_INITIAL=`echo $NEXT_PAGE | sed 's/^.*&f=//g' | sed 's/&p=.*$//g'`
#echo $F_INITIAL
HEADER=`echo $NEXT_PAGE | sed 's/&f=.*$//g'`
#echo $HEADER
PAGE=1
i=0
while [ "$i" -le "1000" ]
do
	PIC_URL=`grep "&p="$i"\"" ./wretch_tmp.html |\
	sed 's/^.*a href=".//g' | sed 's/">.*$//g'`
	NEXT_PAGE=`echo "http://www.wretch.cc/album"$PIC_URL`
	curl -e $IN_URL -o wretch_tmp2.html  $NEXT_PAGE
	EXIST=`grep 'DisplayImage' ./wretch_tmp2.html | wc -c`
	echo $EXIST
	if [ "$EXIST" -ne "0" ]; then
		JPG_URL=`grep 'DisplayImage' ./wretch_tmp2.html |\
		sed "s/^.*src='//g"  | sed "s/' border=0.*$//g"`
		#echo $JPG_URL
		PROG=$[$i + 1]
		echo "======================Downloading JPG file No."$PROG "======================"
		curl -e $IN_URL -O $JPG_URL
		i=$[$i + 1]
	else
		PAGE=$[$PAGE + 1]
		curl -e "http://www.wretch.cc" -o wretch_tmp.html $IN_URL"&page="$PAGE
		EXIST=`grep "&p="$i"\"" ./wretch_tmp.html | wc -c`
		if [ "$EXIST" -eq "0" ]; then
			break
		fi
	fi
done
rm ./wretch_tmp.html
rm ./wretch_tmp2.html
echo "All done."
