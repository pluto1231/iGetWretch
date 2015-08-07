#iGetWretch V0.53b UNIX updated 2012/09/05
#!/bin/bash

#Get album address

echo "Enter Album address"
read IN_URL
USER=`echo $IN_URL | sed  's/^.*id=//g' | sed 's/&book=.*$//g'`
ALBUM=`echo $IN_URL | sed  's/^.*book=//g'`

#Create directory
mkdir ~/Wretch_Album
cd ~/Wretch_Album
mkdir ./$USER"_"$ALBUM
cd ./$USER"_"$ALBUM

#Detect number of items in the album
curl -e "http://www.wretch.cc" -o wretch_album.html "http://www.wretch.cc/album/"$USER
NUM_OF_ITEM=`grep -A 7 '&book='$ALBUM'"' ./wretch_album.html |\
grep -A 1 '<font class="small-c">' |\
grep ' </font>' | sed 's/[^0-9]*//' | sed 's/[^0-9].*$//g'`
echo $NUM_OF_ITEM" items in album"
#Set Mode, BASIC: $MODE=0; Expert: $MODE=1
echo "Enter mode, 0=Basic, 1=Expert"    
read MODE
if [ "$MODE" -eq "0" ]; then
	BEGIN_NUM=0
	END_NUM=$[$NUM_OF_ITEM - 1]
	DELAY=0
else
	#Get begin and end numbers
    echo "Enter begin number(0 is the first item)"
	read BEGIN_NUM    
	echo "Enter end number"
	read END_NUM 
	#Get delay time    
	echo "Enter delay time(second)"
	read DELAY
	NUM_OF_ITEM=$[$END_NUM - $BEGIN_NUM + 1]
fi
echo "BEGIN is"$BEGIN_NUM
echo "END is"$END_NUM
echo "NUM_OF_ITEM is "$NUM_OF_ITEM





#Fetch and analyze URL to get each album page
curl -e "http://www.wretch.cc" -o wretch_tmp.html $IN_URL
SUCCESS=`cat wretch_tmp.html | grep '<a href="./show.php?' | wc -c`
echo "SUCCESS is "$SUCCESS

PIC_URL=`grep "&p=0&sp=1\"" ./wretch_tmp.html | grep "><a href" |\
sed 's/^.*><a href=".//g' | sed 's/">.*$//g'`
echo "PIC_URL is "$PIC_URL
SP_COUNT=`echo $PIC_URL | wc -c`
echo "SP_COUNT= "$SP_COUNT
if [ "$SP_COUNT" -ge "3" ]; then
	SP=1
else
	SP=0
fi
echo "SP= "$SP
PIC_URL=`grep "&p=0&sp=$SP\"" ./wretch_tmp.html | grep "><a href" |\
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
while [ "$i" -le "$END_NUM" ]
do
	echo "in loop, i= "$i
	PIC_URL=`grep "&p="$i"&sp=$SP\"" ./wretch_tmp.html |\
	grep "><a href" |\
	sed 's/^.*><a href=".//g' | sed 's/">.*$//g'`
	echo "PIC_URL is "$PIC_URL
	NEXT_PAGE=`echo "http://www.wretch.cc/album"$PIC_URL`
	echo "NEXT_PAGE is "$NEXT_PAGE
	#Fetch and analyze album pages to get URL of pages containing each photo
	curl -e "http://www.wretch.cc" -o wretch_tmp2.html  $NEXT_PAGE
	EXIST=`grep 'displayimg' ./wretch_tmp2.html | wc -c`
	echo "EXIST is "$EXIST
	if [ "$EXIST" -ne "0" ]; then
		DISP_IMG="displayimg"
	else
		EXIST=`grep 'DisplayImage' ./wretch_tmp2.html | wc -c`
		if [ "$EXIST" -ne "0" ]; then
			DISP_IMG="DisplayImage"
		fi
	fi
	echo "DISP_IMG= "$DISP_IMG
	if [ "$EXIST" -ne "0" ]; then
		#Fetch and analyze photo pages to get the actual URL of photo
		JPG_URL=`grep $DISP_IMG ./wretch_tmp2.html |\
		sed "s/^.*src='//g"  | sed "s/' alt=.*$//g"`
		BORDER_EXIST=`echo $JPG_URL | grep 'border=0' | wc -c`
		echo "BORDER_EXIST= "$BORDER_EXIST
		if [ "$BORDER_EXIST" -ne "0" ]; then
			JPG_URL=`grep $DISP_IMG ./wretch_tmp2.html |\
			sed "s/^.*src='//g"  | sed "s/' border=0.*$//g"`
		fi
		echo "JPG_URL="$JPG_URL
		PROG=$[$i + 1]
		echo "== Downloading item "\$[$PROG - $BEGIN_NUM]" of "  $NUM_OF_ITEM "=="
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
		 	echo "== Downloading item "$[$PROG - $BEGIN_NUM] " of "  $NUM_OF_ITEM "=="
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
				echo "MP3_URL="$MP3_URL
				PROG=$[$i + 1]
		 		echo "== Downloading item "$[$PROG - $BEGIN_NUM] " of "  $NUM_OF_ITEM "=="
				sleep $DELAY
				curl -e "http://www.wretch.cc" -o $[$PROG - $BEGIN_NUM]".mp3" $MP3_URL
				i=$[$i + 1]
			else
				#Go to next album page
				PAGE=$[$PAGE + 1]
				curl -e "http://www.wretch.cc" -o wretch_tmp.html $IN_URL"&page="$PAGE
				EXIST=`grep "&p="$i"&sp=$SP\"" ./wretch_tmp.html | wc -c`
				#No more photos
				if [ "$EXIST" -eq "0" ]; then
					break
				fi
			fi
		fi
	fi
done


#rm ./wretch_album.html
#rm ./wretch_tmp.html
#rm ./wretch_tmp2.html
if [ "$SUCCESS" -eq "0" ]; then
	echo "Album is Protected!"
else
	echo "All items have been successfully downloaded!"
fi