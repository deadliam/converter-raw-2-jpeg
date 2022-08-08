#! /bin/bash

WORKING_DIR=$( pwd )

function help() {
    echo "Usage: $(basename "$0") -d|--source-dir <source-directory> -s|--size <megabytes> -f|--format <extension>"
    echo ""
    echo "Options:"
    echo "  -d, --source-dir"
    echo "      set source directory with images"
    echo "  -s, --size"
    echo "      set maximum size of result image"
	echo "  -f, --format"
    echo "      set result image extension"
    echo "  -g, --hight"
    echo "      set result image hight in pixels"
	echo "  -w, --width"
    echo "      set result image width in pixels"
    echo "  -h, --help"
    echo "      display this help"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") -d ~/Desktop/raw-images -s 10 -f jpeg"
    exit 0
}

while test $# -gt 0; do
    case $1 in
    	-d|--source-dir) SOURCE_DIR="$2"
            shift;;
        -s|--size) RESULT_MAX_SIZE="$2"
            shift;;
        -f|--format) RESULT_FORMAT="$2"
            shift;;
        -g|--hight) RESAMPLE_HIGHT="$2"
            shift;;
        -w|--width) RESAMPLE_WIDTH="$2"
            shift;;
        -h|--help)
            help;;
        *) echo "Unknown option $1. Run with --help or -h for help."
            exit 1;;
    esac
    shift
done

if [ -z $SOURCE_DIR ]; then
	echo "===================================="
	echo "Source directory is not specified"
	echo "===================================="
	help
	exit 0
fi

if [ -z $RESULT_FORMAT ]; then
	echo "===================================="
	echo "Format of result image is not specified"
	echo "===================================="
	help
	exit 0
fi

RESAMPLE_HIGHT_OPTION=""
if [ ! -z "${RESAMPLE_HIGHT}" ]; then
	RESAMPLE_HIGHT_OPTION="--resampleHeight $RESAMPLE_HIGHT"
fi

RESAMPLE_WIDTH_OPTION=""
if [ ! -z "${RESAMPLE_WIDTH}" ]; then
	RESAMPLE_WIDTH_OPTION="--resampleWidth $RESAMPLE_WIDTH"
fi

echo "MAX SIZE: $RESULT_MAX_SIZE Mb"
echo "RESULT FORMAT: $RESULT_FORMAT"
echo "SOURCE IMAGES: $SOURCE_DIR"
echo "----------------------------------"

# Default values
RESULT_DIR="result-images"
RESULT_FORMAT="jpeg"

if [ $RESULT_FORMAT == "jpg" ]; then
	RESULT_FORMAT="jpeg"
fi

SHOULD_COMPRESS=false
if [ $RESULT_FORMAT == "jpeg" ]; then
	if [ -z $RESULT_MAX_SIZE ]; then
		echo "===================================="
		echo "Max size of result image is not specified"
		echo "===================================="
		help
		exit 0
	else
		RESULT_MAX_SIZE=$((RESULT_MAX_SIZE * 1000000))
	fi
	SHOULD_COMPRESS=true
fi

function resize()
{
	cd "${SOURCE_DIR}"

	OLD_IFS="$IFS"
	IFS=$'\n'
	FILES=( $(ls *.*) )
	IFS="$OLD_IFS"

	count_i=0
	count_j=0

	for i in "${FILES[@]}"
	do
		if [ -d "${i}" ]; then
			continue
		fi

		QUALITY=100
		FILESIZE=1000000000 # 1000mb
		FILENAME_WITH_EXT=$(basename "$i")
		FILENAME=${FILENAME_WITH_EXT%.*}
		EXT="${FILENAME##*.}"

		(( count_i ++ ))
		echo "[$count_i] FILE: [$FILENAME.$RESULT_FORMAT]"

		if $SHOULD_COMPRESS; then

			while [[ $FILESIZE -gt $RESULT_MAX_SIZE ]]
			do
				QUALITY=$((QUALITY - 5))
				if [ -f "$RESULT_DIR/$FILENAME.$RESULT_FORMAT" ]; then
					rm "$RESULT_DIR/$FILENAME.$RESULT_FORMAT"
					(( count_j ++ ))
					echo "RETRY [$count_j] FILE: [$FILENAME.$RESULT_FORMAT] | WITH QUALITY: $QUALITY"
				fi

				/usr/bin/sips $RESAMPLE_WIDTH_OPTION $RESAMPLE_HIGHT_OPTION -s format $RESULT_FORMAT -s formatOptions $QUALITY "${i}" --out $RESULT_DIR/$FILENAME.$RESULT_FORMAT > /dev/null 2>&1
				FILESIZE=$(stat -f%z "$RESULT_DIR/$FILENAME.$RESULT_FORMAT")
			done

		else
			/usr/bin/sips $RESAMPLE_WIDTH_OPTION $RESAMPLE_HIGHT_OPTION -s format $RESULT_FORMAT "${i}" --out $RESULT_DIR/$FILENAME.$RESULT_FORMAT > /dev/null 2>&1
		fi
	done
}

cd "$SOURCE_DIR"
if [ ! -d $RESULT_DIR ]; then
	mkdir "$RESULT_DIR"
fi

resize
