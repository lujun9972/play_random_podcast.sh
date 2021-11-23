#!/usr/bin/env bash

while getopts :cs:p: OPT; do
    case $OPT in
        c|+c)
            cached="True"
            ;;
        s|+s)
            store_directory="$OPTARG"
            ;;
        p|+p)
            player="$OPTARG"
            ;;
        *)
            echo "usage: ${0##*/} [-c][-s STORE_DIRECTORY][-p PLAYER] [--] PODCAST_FEED"
            exit 2
    esac
done
shift $(( OPTIND - 1 ))
OPTIND=1

podcast_feed=$1
player=${player:-mpg123}
random_item=$(curl -L ${podcast_feed} |hxselect -c 'item' -s "\0" |shuf -z|head -z -n 1)
enclosure_url=$(echo "${random_item}" |hxselect -s "\n" 'enclosure::attr(url)' -c )
title=$(echo "${random_item}" |hxselect -s "\n" 'title' -c |sed 's/<!\[CDATA\[//'|sed 's/]]>//')
echo "enclosure=${enclosure_url}"
echo "title=${title}"
# 缓存mp3
if [[ -n ${cached} ]];then
    if [[ -z ${store_directory} ]];then
	podcast=$(echo ${podcast_feed}|sed 's#^https*://\([^/]*\).*$#\1#')
        store_directory=$(dirname $0)/podcasts/${podcast}
    fi
    mkdir -p ${store_directory}
    cd ${store_directory}
    extension="${enclosure_url##*.}"
    enclosure_file="${title}.${extension}"
    if [[ ! -f ${enclosure_file} ]];then
        wget ${enclosure_url} -O "${enclosure_file}"
    fi
    # 播放mp3文件
    $player "${enclosure_file}"
else
    # 播放mp3 URL
    curl -L ${enclosure_url}|$player - # mpg123本身只支持http协议
fi
