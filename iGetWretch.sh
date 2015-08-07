#iGetWretch V0.52b updated 2011/11/19
#!/bin/bash
CD="CocoaDialog.app/Contents/MacOS/CocoaDialog"
#Get album address
rv=`$1/Contents/Resources/$CD standard-inputbox --title "Wretch Album Address" --no-newline \\
    --informative-text "Enter Album address"` 
IN_URL=`echo $rv | sed 's/^.*1\ //g'`
USER=`echo $IN_URL | sed  's/^.*id=//g' | sed 's/&book=.*$//g'`
ALBUM=`echo $IN_URL | sed  's/^.*book=//g'`

#Create directory
mkdir ~/Wretch_Album
cd ~/Wretch_Album
mkdir ./$USER"_"$ALBUM
cd ./$USER"_"$ALBUM

#Detect number of items in the album
curl -e "http://www.wretch.cc" -o wretch_album.html "http://www.wretch.cc/album/"$USER
NUM_OF_ITEM=`grep -A 7 '&book='$ALBUM'"' ./wretch_album.html | grep -A 1 '<font class="small-c">' |\
grep ' </font>' | sed 's/[^0-9]*//' | sed 's/[^0-9].*$//g'`
echo $NUM_OF_ITEM" items in album"
#Set Mode, BASIC: $MODE=0; Expert: $MODE=1
rv5=`$1/Contents/Resources/$CD standard-dropdown --title "Mode" \\
    --text "Choose Mode: " --items "Basic" "Expert"`
MODE=`echo $rv5 | sed 's/^.*1\ //g'`
if [ "$MODE" -eq "0" ]; then
	BEGIN_NUM=0
	END_NUM=$[$NUM_OF_ITEM - 1]
	DELAY=0
else
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
	NUM_OF_ITEM=$[$END_NUM - $BEGIN_NUM + 1]
fi
echo "BEGIN is"$BEGIN_NUM
echo "END is"$END_NUM
echo "NUM_OF_ITEM is"$NUM_OF_ITEM



#Create and  link pipe
rm -f /tmp/hpipe
mkfifo /tmp/hpipe


#Fetch and analyze URL to get each album page
curl -e "http://www.wretch.cc" -o wretch_tmp.html $IN_URL
SUCCESS=`cat wretch_tmp.html | grep '<a href="./show.php?' | wc -c`
echo "$SUCCESS is "$SUCCESS
#if [ "$SUCCESS" -eq "0" ]; then
#	rv6=`$1/Contents/Resources/$CD fileselect \
#	--title "Protected album"\
#  	--text "Input album html file: " \
#  	--with-extensions .htm .html`
#$1/Contents/Resources/$CD bubble --debug --title "Done" --text "All items have been successfully downloaded!"
#fi
#echo "rv6 is "$rv6
#cp $rv6 ./wretch_tmp.html

PIC_URL=`grep "&p=0&sp=0\"" ./wretch_tmp.html | grep "><a href" |\
sed 's/^.*><a href=".//g' | sed 's/">.*$//g'`
echo "PIC_URL is "$PIC_URL
NEXT_PAGE=`echo "http://www.wretch.cc/album"$PIC_URL`
echo "NEXT_PAGE is "$NEXT_PAGE
F_INITIAL=`echo $NEXT_PAGE | sed 's/^.*&f=//g' | sed 's/&p=.*$//g'`
echo "F_INITIAL is "$F_INITIAL
HEADER=`echo $NEXT_PAGE | sed 's/&f=.*$//g'`
echo "HEADER is "$HEADER
PAGE=1
i=$BEGIN_NUM
$1/Contents/Resources/$CD progressbar --title "Progress" --indeterminate < /tmp/hpipe &
exec 3<> /tmp/hpipe
while [ "$i" -le "$END_NUM" ]
do
	echo "in loop, i= "$i
	PIC_URL=`grep "&p="$i"&sp=0\"" ./wretch_tmp.html |\
	grep "><a href" |\
	sed 's/^.*><a href=".//g' | sed 's/">.*$//g'`
	echo "PIC_URL is "$PIC_URL
	NEXT_PAGE=`echo "http://www.wretch.cc/album"$PIC_URL`
	echo "NEXT_PAGE is "$NEXT_PAGE
	#Fetch and analyze album pages to get URL of pages containing each photo
	curl -e "http://www.wretch.cc" -o wretch_tmp2.html  $NEXT_PAGE
	EXIST=`grep 'DisplayImage' ./wretch_tmp2.html | wc -c`
	if [ "$EXIST" -ne "0" ]; then
		#Fetch and analyze photo pages to get the actual URL of photo
		JPG_URL=`grep 'DisplayImage' ./wretch_tmp2.html |\
		sed "s/^.*src='//g"  | sed "s/' border=0.*$//g"`
		echo "JPG_URL="$JPG_URL
		PROG=$[$i + 1]
		echo "0 Downloading $[$PROG - $BEGIN_NUM] of $NUM_OF_ITEM" >&3
		echo "================= Downloading item "$[$PROG - $BEGIN_NUM]" of "  $NUM_OF_ITEM "================="
		sleep $DELAY
		curl -e $IN_URL -o $[$PROG - $BEGIN_NUM]".jpg" $JPG_URL
		i=$[$i + 1]
	else
		#No photo -> video?
		EXIST=`grep '"flashvars","' ./wretch_tmp2.html | wc -c`		
		if [ "$EXIST" -ne "0" ]; then
			#Fetch and analyze video pages to get the actual URL of video
			FLV_URL=`grep '"flashvars","' ./wretch_tmp2.html |\
			sed 's/^.*file=//g' | sed 's/",.*$//g'`
			PROG=$[$i + 1]
			echo "0 Downloading $[$PROG - $BEGIN_NUM] of $NUM_OF_ITEM" >&3
		 	echo "================= Downloading item "$[$PROG - $BEGIN_NUM] " of "  $NUM_OF_ITEM "================="
			sleep $DELAY
			curl -e "http://www.wretch.cc" -o $[$PROG - $BEGIN_NUM]".flv" $FLV_URL
			i=$[$i + 1]
		else
			#No photo and video -> music?
			EXIST=`grep ".mp3" ./wretch_tmp2.html | wc -c`
			if [ "$EXIST" -ne "0" ]; then
				#Fetch  and analyze music pages to get the actual URL of video
				MP3_URL=`grep ".mp3" ./wretch_tmp2.html | grep "file:" |\
				sed 's/^.*: .//g' | sed 's/",.*//g'`
				PROG=$[$i + 1]
				echo "0 Downloading $[$PROG - $BEGIN_NUM] of $NUM_OF_ITEM" >&3
		 		echo "================= Downloading item "$[$PROG - $BEGIN_NUM] " of "  $NUM_OF_ITEM "================="
				sleep $DELAY
				curl -e "http://www.wretch.cc" -o $[$PROG - $BEGIN_NUM]".mp3" $MP3_URL
				i=$[$i + 1]
			else
				#Go to next album page
				PAGE=$[$PAGE + 1]
				curl -e "http://www.wretch.cc" -o wretch_tmp.html $IN_URL"&page="$PAGE
				EXIST=`grep "&p="$i"&sp=0\"" ./wretch_tmp.html | wc -c`
				#No more photos
				if [ "$EXIST" -eq "0" ]; then
					break
				fi
			fi
		fi
	fi
done


exec 3>&-
wait
rm -f /tmp/hpipe
rm ./wretch_album.html
rm ./wretch_tmp.html
rm ./wretch_tmp2.html
if [ "$SUCCESS" -eq "0" ]; then
	$1/Contents/Resources/$CD bubble --debug --title "Fail" --text "Album is Protected!"
else
	$1/Contents/Resources/$CD bubble --debug --title "Done" --text "All items have been successfully downloaded!"
fi
open ./