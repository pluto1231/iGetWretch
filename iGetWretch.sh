#iGetWretch V0.4b
#!/bin/bash
CD="./CocoaDialog.app/Contents/MacOS/CocoaDialog"
#Get album address
rv=`$1/Contents/Resources/$CD standard-inputbox --title "Wretch Album Address" --no-newline \\
    --informative-text "Enter Album address"` 
IN_URL=`echo $rv | sed 's/^.*1\ //g'`
USER=`echo $IN_URL | sed  's/^.*id=//g' | sed 's/&book=.*$//g'`
ALBUM=`echo $IN_URL | sed  's/^.*book=//g'`
#Get begin and end numbers
rv2=`$1/Contents/Resources/$CD standard-inputbox --title "Photo Begin No." --no-newline \\
    --informative-text "Enter begin number(0 is the first item)"` 
BEGIN_NUM=`echo $rv2 | sed 's/^.*1\ //g'`    
rv3=`$1/Contents/Resources/$CD standard-inputbox --title "Photo End No." --no-newline \\
    --informative-text "Enter end number"`
END_NUM=`echo $rv3 | sed 's/^.*1\ //g'` 
#Get delay time    
rv4=`$1/Contents/Resources/$CD standard-inputbox --title "Delay Time" --no-newline \\
    --informative-text "Enter delay time(second)"`
DELAY=`echo $rv4 | sed 's/^.*1\ //g'`
echo "Downloading html source code..."
#Set delay time
#Create directory
mkdir ~/Wretch_Album
cd ~/Wretch_Album
mkdir ./$USER"_"$ALBUM
cd ./$USER"_"$ALBUM
#Fetch and analyze URL to get each album page
curl -e "http://www.wretch.cc" -o wretch_tmp.html $IN_URL
PIC_URL=`grep "&p=0\"" ./wretch_tmp.html |\
sed 's/^.*a href=".//g' | sed 's/">.*$//g'`
NEXT_PAGE=`echo "http://www.wretch.cc/album"$PIC_URL`
F_INITIAL=`echo $NEXT_PAGE | sed 's/^.*&f=//g' | sed 's/&p=.*$//g'`
HEADER=`echo $NEXT_PAGE | sed 's/&f=.*$//g'`
PAGE=1
i=$BEGIN_NUM
while [ "$i" -le "$END_NUM" ]
do
	PIC_URL=`grep "&p="$i"\"" ./wretch_tmp.html |\
	sed 's/^.*a href=".//g' | sed 's/">.*$//g'`
	NEXT_PAGE=`echo "http://www.wretch.cc/album"$PIC_URL`
	#Fetch and analyze album pages to get URL of pages containing each photo
	curl -e $IN_URL -o wretch_tmp2.html  $NEXT_PAGE
	EXIST=`grep 'DisplayImage' ./wretch_tmp2.html | wc -c`
	if [ "$EXIST" -ne "0" ]; then
		#Fetch and analyze photo pages to get the actual URL of photo
		JPG_URL=`grep 'DisplayImage' ./wretch_tmp2.html |\
		sed "s/^.*src='//g"  | sed "s/' border=0.*$//g"`
		PROG=$[$i + 1]
		echo "================= Downloading item "$[$PROG - $BEGIN_NUM]" of "  $[$END_NUM - $BEGIN_NUM + 1] "================="
		sleep $DELAY
		curl -e $IN_URL -O $JPG_URL
		i=$[$i + 1]
	else
		#No photo -> video?
		EXIST=`grep '"flashvars","' ./wretch_tmp2.html | wc -c`		
		if [ "$EXIST" -ne "0" ]; then
			#Fetch and analyze video pages to get the actual URL of video
			FLV_URL=`grep '"flashvars","' ./wretch_tmp2.html |\
			sed 's/^.*file=//g' | sed 's/",.*$//g'`
			PROG=$[$i + 1]
		    echo "================= Downloading item "$[$PROG - $BEGIN_NUM] " of "  $[$END_NUM - $BEGIN_NUM + 1] "================="
			sleep $DELAY
			curl -e $IN_URL -O $FLV_URL
			i=$[$i + 1]
		else
			#Go to next album page
			PAGE=$[$PAGE + 1]
			curl -e "http://www.wretch.cc" -o wretch_tmp.html $IN_URL"&page="$PAGE
			EXIST=`grep "&p="$i"\"" ./wretch_tmp.html | wc -c`
			#No more photos
			if [ "$EXIST" -eq "0" ]; then
				break
			fi
		fi
	fi
done
rm ./wretch_tmp.html
rm ./wretch_tmp2.html
echo "All done."
