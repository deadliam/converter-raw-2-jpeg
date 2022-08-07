#! /bin/bash

# 1. конвертация из PSD или PNG в  Jpeg
# 2. размер файла не должен превышать 10mb, но при этом быть не ниже 5-6 mb

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
    echo "  -h, --help"
    echo "      display this help"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") -d ~/Desktop/raw-images -s 10 -f jpeg"
    exit 0
}

# Default extension for result image
RESULT_DIR="result-images"
RESULT_FORMAT="jpeg"
RESULT_MAX_SIZE=10000000 # 10mb

while test $# -gt 0; do
    case $1 in
    	-d|--source-dir) SOURCE_DIR="$2"
            shift;;
        -s|--size) RESULT_MAX_SIZE="$2"
            shift;;
        -f|--format) RESULT_FORMAT="$2"
            shift;;
        -h|--help)
            help;;
        *) echo "Unknown option $1. Run with --help or -h for help."
            exit 1;;
    esac
    shift
done

echo "MAX SIZE: $RESULT_MAX_SIZE Mb"
echo "RESULT FORMAT: $RESULT_FORMAT"
echo "SOURCE IMAGES: $SOURCE_DIR"
echo "----------------------------------"

RESULT_MAX_SIZE=$((RESULT_MAX_SIZE * 1000000))

function resize()
{
	FILES=($SOURCE_DIR/*)

	count_i=0
	count_j=0
	for i in "${FILES[@]}"
	do
		if [ -d "$i" ]; then
			continue
		fi

		QUALITY=100
		FILESIZE=1000000000 # 1000mb
		FILENAME=(`basename ${i%%.*}`)
		EXT=${i##*.}

		(( count_i ++ ))
		echo "[$count_i] FILE: [$FILENAME.$EXT]"
		while [[ $FILESIZE -gt $RESULT_MAX_SIZE ]]
		do
			QUALITY=$((QUALITY - 5))
			if [ -f "$RESULT_DIR/$FILENAME.$RESULT_FORMAT" ]; then
				rm "$RESULT_DIR/$FILENAME.$RESULT_FORMAT"
				(( count_j ++ ))
				echo "RETRY [$count_j] FILE: [$FILENAME.$EXT] | WITH QUALITY: $QUALITY"
			fi
			/usr/bin/sips -s format $RESULT_FORMAT -s formatOptions $QUALITY "${i}" --out $RESULT_DIR/$FILENAME.$RESULT_FORMAT > /dev/null 2>&1
			FILESIZE=$(stat -f%z "$RESULT_DIR/$FILENAME.$RESULT_FORMAT")
		done
	done
}

cd "$SOURCE_DIR"
if [ ! -d $RESULT_DIR ]; then
	mkdir "$RESULT_DIR"
fi

resize
