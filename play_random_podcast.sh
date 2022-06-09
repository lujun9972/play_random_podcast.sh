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
# sed多行合并为一行
# :a 在代码开始处设置一个标记a，在代码执行到结尾处时利用跳转命令t a重新跳转到标号a处，重新执行代码，这样就可以递归的将所有行合并成一行
# N 命令，将下一行读入并附加到当前行后面。
title=$(echo "${item}" |hxselect -s "\n" 'title' -c |sed 's/<!\[CDATA\[//'|sed 's/]]>//'|sed ':a;N;s/^[ \r\n\t$]*//;s/[ \r\n\t$]*$//; t a;')
echo "enclosure=${enclosure_url}"
echo "title=${title}"

function formatFileName()
{
    echo "$*" |sed 's/[:*?<>|"]/_/g'
}

# 缓存mp3
if [[ -n ${cached} ]];then
    if [[ -z ${store_directory} ]];then
	podcast=$(echo ${podcast_feed}|sed 's#^https*://\([^/]*\).*$#\1#')
        store_directory=$(dirname $0)/podcasts/${podcast}
    fi
    echo mkdir -p ${store_directory}
    mkdir -p ${store_directory}
    extension="${enclosure_url##*.}"
    enclosure_file="${store_directory}/$(formatFileName "${title}.${extension}")"
    if [[ ! -f ${enclosure_file} ]];then
        wget ${enclosure_url} -O "${enclosure_file}"
    fi
    # 播放mp3文件
    $player "${enclosure_file}"
else
    # 播放mp3 URL
    curl -L ${enclosure_url}|$player - # mpg123本身只支持http协议
fi
