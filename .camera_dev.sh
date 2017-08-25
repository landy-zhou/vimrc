# 如果开机无法detect camera，图标会消失，用这个脚本可以重新检测，免得恢复出厂设置等几分钟
alias unhidecamera='adb wait-for-device; ! adb root | grep -e already && adb wait-for-device; adb shell rm /data/system/users/0/package-restrictions.xml && adb reboot' # fail only if device not found, not including file not found, no permission, which should not happen
 
# push code或者camera hang时，可以用来杀掉cameraserver，免得重启
alias kimedia='adb shell kill -KILL `adb shell ps | grep cameraserver | sed -e"s/^\w\w*\s*\([0-9]\{1,\}\)\s.*/\1/g"`; (adb shell pkill -l KILL gallery; adb shell pkill -l KILL camera; adb shell pkill -l KILL GoogleCamera) &>/dev/null'
 
# 抓log到~/ll，会保存所有的log到/tmp/*，因为是通过硬链接的方式，所以不会把相同的数据保存两份
alias logcf='LL="ll.$(date +%F.%T)"; touch /tmp/"$LL"; ln -f /tmp/"$LL" ~/ll; adb wait-for-device; adb logcat -c | grep permitted && (adb root; adb wait-for-device; adb logcat -c); adb logcat -v threadtime *:v | tee /tmp/"$LL"'
 
# 拷贝所有的照片录像并清除手机照片录像
alias pulldcim='adb pull /sdcard/DCIM/Camera/ && adb shell rm -rf /sdcard/DCIM/Camera/*'
 
# enable kernel trace log
alias enable_trace='adb root && adb shell "echo 1 > /sys/kernel/debug/tracing/tracing_on  && echo 5000 > /sys/kernel/debug/tracing/buffer_size_kb && echo 0x100 > /sys/kernel/debug/plat-cam/open_log"'
# save kernel trace log
alias pull_trace='adb root && adb pull /sys/kernel/debug/tracing/trace ~/ext_disk/Work/USB_download/kernel_trace.log'

#清除手机照片录像
alias cleandcim='adb shell rm -rf /sdcard/DCIM/Camera/*'
 
# 可以在任何一个目录执行 mminit （默认使用evb），也可以用参数指定 mminit evb ，来进行自动lunch，然后跳回原来的目录
function mminit() {
pushd . &>/dev/null
selected_product=
while [ ! -f "./build/envsetup.sh" ]; do
    if [ "$PWD" = "/" ]; then
        echo envsetup.sh not found!
        popd &>/dev/null
        return 2
    fi
    cd ..
done
 
pushd ./device/ &>/dev/null
products="$(for i in marvell/* asr/*; do grep $i -rle 'PRODUCT_NAME\s*:=' 2>/dev/null | sort -r; done)"
#echo "$products"
 
if [ -n "$1" ]; then
    for arg in $products; do
        if echo "$arg" | grep "$1" &>/dev/null; then
            selected_product=$arg
            #echo arg=$arg
            break
        fi
    done
fi
 
if [ -n "$selected_product" ]; then
    echo "Selected product:"
    echo "$products" | grep -ne '.' | grep "^\|^.*$selected_product.*"
else
    echo "Auto selecting the first product: (use \"mminit pattern\" to override)"
    selected_product=$( echo "$products" | head -1 )
    echo "$products" | grep -ne '.' | grep "^\|^.*$selected_product"
fi
 
pn=$(grep $selected_product -e "PRODUCT_NAME.*=" | head -1 | sed -e"s/^.*:= *\(\w*\)/\1/g")
echo " "$'\n'"PRODUCT_NAME=$pn" | grep -e '.'
popd &>/dev/null
 
source "./build/envsetup.sh" &>/dev/null
echo "LUNCH=$pn-userdebug" | grep -e '.'
lunch "$pn-userdebug"
 
popd &>/dev/null
}
 
# 自动编译当前目录，然后把生成的lib等push到开发板
function mmr() {
    if [ -z "$ANDROID_PRODUCT_OUT" ]; then
        echo Run mminit first! | grep .
        mminit
    fi
    trap "popd; trap - SIGINT" SIGINT
    pushd . &>/dev/null
    dst=~/.mmreplace
    if [ ! -d "$dst" ]; then
        mkdir "$dst"
    fi
    rm -f "$dst/push"
    while [ ! -f "Android.mk" ]; do
        if [ "$PWD" = "/" ]; then
            echo Project not found!
            popd &>/dev/null
            return
        fi
        cd ..
    done
    echo Current project is $(pwd) | grep '/.*'
    pwdsum=$(echo $TARGET_PRODUCT.$(pwd) | md5sum | sed -e's/ .*//')
    if [[ "$1" =~ [Bb] ]]; then
        echo Delete record: "$dst/$pwdsum" | grep '/.*'
        rm "$dst/$pwdsum"
    fi
    if [ -e "$dst/$pwdsum" ] && grep "$dst/$pwdsum" -e '.' &>/dev/null; then
        echo Found record: "$dst/$pwdsum" | grep '/.*'
        ( mm -j8 && touch "$dst/push" ) | grep "Install:" | sed -e"s/^.*Install: //" | while read so; do
            if ! grep "$dst/$pwdsum" -Fe "$so" &>/dev/null; then
                echo Append to record: "$so" | grep -e 'out.*'
                echo "$so" >> "$dst/$pwdsum"
            fi
        done
    else
        echo Record not found: "$dst/$pwdsum" | grep '/.*'
        find . -iname "*.c" -o -iname "*.cpp" | while read line; do echo "workaround: touching $line"; touch $line; done
        ( mm -B -j8 && touch "$dst/push" ) | grep "Install:" | sed -e"s/^.*Install: //" > "$dst/$pwdsum"
        echo New record:
        cat "$dst/$pwdsum" | grep -e '.'
    fi
 
    if [ -f "$dst/push" ]; then
        if [[ "$1" =~ [Ll] ]]; then
            if [[ "$1" =~ [Kk] ]]; then
                echo Keep /system !
            else
                echo Clean /system !
                find /system/ -type f | xargs rm
            fi
        else
            echo Trying to remount /system !
            if [[ "$1" =~ [Ss] ]]; then
                adb -s "$2" wait-for-device
                (adb -s "$2" remount | grep succeeded || (adb -s "$2" root; adb -s "$2" wait-for-device; adb -s "$2" remount)) | cat
            else
                adb wait-for-device
                (adb remount | grep succeeded || (adb root; adb wait-for-device; adb remount)) | cat
            fi
        fi
 
        cat "$dst/$pwdsum" | while read so; do
            if [[ "$1" =~ [Aa] ]]; then
                if [[ "$so" == *.yuv ]]; then
                    continue
                fi
            else
                if [[ "$so" == *.xml || "$so" == *.yuv || "$so" == *.data || "$so" == *.txt ]]; then
                    continue
                fi
            fi
            pushd . &>/dev/null
            while [ ! -e "./build/envsetup.sh" ]; do
                if [ "$PWD" = "/" ]; then
                    echo Code Base not found!
                    popd &>/dev/null
                    break
                fi
                cd ..
            done
 
            if [[ "$1" =~ [Ll] ]]; then
                echo "$PWD/$so -> /system/${so#*/system/}" | grep " /system/.*"
                cp "./$so" "/system/${so#*/system/}"
            else
                if [[ "$1" =~ [Ss] ]]; then
                    echo "$PWD/$so -> /system/${so#*/system/} [$2] " | grep " /system/.*"
                    adb -s "$2" push "./$so" "/system/${so#*/system/}"
                    ls -l "$PWD/$so" | awk '{print $9"  --size--  "$5}'
                    adb shell ls -l "/system/${so#*/system/}" | awk '{print $8"  --size--  "$5}'
                    size1=$(ls -l "$PWD/$so" | awk '{print $5}')
                    size2=$(adb shell ls -l "/system/${so#*/system/}" | awk '{print $5}')
                    md5sum1=$(md5sum "$PWD/$so" | awk '{print $1}')
                    md5sum2=$(adb shell md5sum "/system/${so#*/system/}" | awk '{print $1}')
                    if [ "$size1" != "$size2" ] || [ "$md5sum1" != "$md5sum2" ]; then
                        echo -e "\033[47;31m adb push error! please retry again\033[0m"
                    else
                        echo -e "\033[47;32m adb push verified OK, successed\033[0m"
                    fi
                else
                    echo "$PWD/$so -> /system/${so#*/system/}" | grep " /system/.*"
                    adb push "./$so" "/system/${so#*/system/}"
                    ls -l "$PWD/$so" | awk '{print $9"  --size--  "$5}'
                    adb shell ls -l "/system/${so#*/system/}" | awk '{print $8"  --size--  "$5}'
                    size1=$(ls -l "$PWD/$so" | awk '{print $5}')
                    size2=$(adb shell ls -l "/system/${so#*/system/}" | awk '{print $5}')
                    md5sum1=$(md5sum "$PWD/$so" | awk '{print $1}')
                    md5sum2=$(adb shell md5sum "/system/${so#*/system/}" | awk '{print $1}')
                    if [ "$size1" != "$size2" ] || [ "$md5sum1" != "$md5sum2" ]; then
                        echo -e "\033[47;31m adb push error! please retry again\033[0m"
                    else
                        echo -e "\033[47;32m adb push verified OK, successed\033[0m"
                    fi
                fi
            fi
            popd &>/dev/null
        done
        if [[ "$1" =~ [Ll] ]]; then
            rm /smb/system.tgz
            tar -cvzf /smb/system.tgz /system
        fi
    fi
    popd &>/dev/null
    trap - SIGINT
}
 
# gxy 320 240 file.nv12 将dump下来的nv12图像以灰度显示
function gxy() { # nv21/nv12 display as greyscale
    if ! [ "$1" -gt 0 ]; then
        echo width cannot be  "$1"!
        return 1
    fi
    x="$1"
    if ! [ "$2" -gt 0 ]; then
        echo height cannot be  "$2"!
        return 1
    fi
    y="$2"
 
    cmd=
    while [ "$#" -gt 2 ]; do
        if [ -f "$3" ]; then
            cmd="$cmd"'run("Raw...", "open='"$3"' image=[8-bit] width='"$x"' height='"$y"' little-endian");'
        else
            echo "$3" does not exist!
        fi
        shift
    done
 
 
    if [ -z "$cmd" ]; then
        echo need to provide at least one file!
        return 1
    fi
 
    imagej -e "$cmd"
}
 
# nxy 320 240 file.nv12 将dump下来的nv12图像以彩色显示
function nxy() { # nv12 to bmp and display
    if ! [ "$1" -gt 0 ]; then
        echo width cannot be  "$1"!
        return 1
    fi
    x="$1"
    if ! [ "$2" -gt 0 ]; then
        echo height cannot be  "$2"!
        return 1
    fi
    y="$2"
 
    if [ -n "$4" ]; then
        cat "$3" | avconv -f rawvideo -pix_fmt "$4" -s "$x"x"$y" -i - %04d.bmp
        if [ -f "0001.bmp" ]; then
            mv 0001.bmp "$3.$4.bmp"
            setsid gpicview "$3.$4.bmp" &>/dev/null
        fi
    else
        cat "$3" | avconv -f rawvideo -pix_fmt nv12 -s "$x"x"$y" -i - %04d.bmp
        if [ -f "0001.bmp" ]; then
            mv 0001.bmp "$3.bmp"
            setsid gpicview "$3.bmp" &>/dev/null
        fi
    fi
    rm 0[0-9][0-9][0-9].bmp &>/dev/null
}
 
# bxy 320 240 file.bayer 将dump下来的bayer图像以彩色显示
function bxy() { # bayer to tiff and display
    if ! [ "$1" -gt 0 ]; then
        echo width cannot be  "$1"!
        return 1
    fi
    x="$1"
    if ! [ "$2" -gt 0 ]; then
        echo height cannot be  "$2"!
        return 1
    fi
    y="$2"
 
    bpp="$4"
    if ((bpp<=0)); then
        bpp=8
    fi
 
    order="$5"
    if [ -z "$order" ]; then
        order="BGGR"
    fi
 
    # https://github.com/jdthomas/bayer2rgb
    echo bayer2rgb -i "$3" -o "$3.tiff" -w "$x" -v "$y" -b "$bpp" -t -m VNG -f "$order"
    bayer2rgb -i "$3" -o "$3.tiff" -w "$x" -v "$y" -b "$bpp" -t -m VNG -f "$order"
    setsid gpicview "$3.tiff" &>/dev/null
}
 
# 在lunch过的shell中，tombstone2line -l ~/ll可以自动将logcat中的所有的crash的地点翻译成文件中的地方
function tombstone2line() {
    OPTIND=1
    while getopts "l:s:" opt; do
        case "$opt" in
            l)
                log="$OPTARG"
                echo "log=$log" 1>&2
                ;;
            s)
                symbols="$OPTARG"
                echo "symbols=$symbols" 1>&2
                ;;
            ?)
                echo "Invalid Arguments, please use:" 1>&2
                echo "./dump_data_process.sh -l adb_logcat [ -s symbols_folder ]" 1>&2
                return 2
                ;;
        esac
    done
 
    if [ -n "$ANDROID_PRODUCT_OUT" ] && [  -z "$symbols" ]; then
        echo "Use current android product out folder $ANDROID_PRODUCT_OUT/symbols as symbols folder" 1>&2
        symbols="$ANDROID_PRODUCT_OUT/symbols"
    fi
 
    if [ "$symbols" == "" ]; then
        echo "Absent Arguments, please use:" 1>&2
        echo "./dump_data_process.sh -l adb_logcat [ -s symbols_folder ]" 1>&2
        return 2
    fi
 
    if [ "$log" == "" ] ; then
        echo "Use ~/ll as default log param!"
        log=~/ll
    fi
 
    if [ ! -e "$log" ]; then
        echo "$log" does not exist 1>&2
        return 2
    fi
 
    if [ ! -d "$symbols" ]; then
        echo "$symbols does not exist or it's not a folder" 1>&2
        return 2
    fi
 
 
    while read line; do
        # 02-14 03:20:33.009  7834  9566 F libc    : Fatal signal 11 (SIGSEGV), code 1, fault addr 0x18 in tid 9566 (CameraHal-proce)
        # 01-11 13:38:47.414   107   107 I DEBUG   :     #00  pc 00013858  /system/lib/libc.so
        # 01-11 13:38:47.414   107   107 I DEBUG   :     #14  pc 00012380  /system/lib/libc.so (pthread_create+172)
        if echo "$line" | grep -e 'Fatal signal ' &>/dev/null; then
            echo
            echo "$line"
            continue
        fi
        tmp="${line#*pc }"
        tmp="${tmp%$'\r'}"
        echo "/${tmp#*/}"
        tmp="${tmp% (*}"
        # 00012380  /system/lib/libc.so
        relativepc="${tmp%% *}"
        lib="${tmp##* }"
        addr2line -e "$symbols/$lib" "$relativepc"
    done <<< "$(sed $log -ne '/Fatal signal/,/Tombstone written to/p' | grep -e '#[0-9]\{1,\}  *pc\|Fatal signal ')"
}
