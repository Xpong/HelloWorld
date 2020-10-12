#!/bin/bash

out=./out

ver_path=/home/work/service/convert/usr/local/hola/script/VERSION
#commit_id=8881d66
commit_id=5a4593f #new bug fixed
ssh_port=4344
ngo=100
user=rd
#ip_file=./cendata/ip.txt
#ip_file=./cendata/ip/main_ip.txt
#ip_file=./cendata/0411/hd300_ok.txt
#ip_file=./cendata/0411/sy.txt
#ip_file=./cendata/0411/hb230.txt
#ip_file=./cendata/0411/main_all.txt
#ip_file=./cendata/0412/300.txt
#ip_file=./cendata/ip/bj.txt
ip_file=./cendata/convertip.txt

#gsignal args
nsig_go=10
time_scale=1.0

#cross signal args
nxsig_go=10
gxsig_file=./cendata/xip.txt

#check log ip list
#ip_log_file=./cendata/ip_cap800.txt
#ip_log_file=./cendata/ip/main_ip.txt
#ip_log_file=./cendata/ip/main_all.txt
ip_log_file=./cendata/ip/newip.txt

#ip_bak_log=./cendata/baklog_localip.txt
ip_bak_log=./cendata/bugip/prd_localip.txt

test -d $out && rm -rf $out
mkdir $out


function show.help() {
    echo "help"
    echo "        check all case"
    echo "-v      check poseidon version"
    echo "-log    check ilogtail"
    exit 0
}

function test.gsh() {
	./gsh -n 10 -f $ip_file -c "test -f $ver_path && cat $ver_path | grep $commit_id | wc -l"
}

#check relay version -p 4344
function psd.check.version() {
	./gsh -n $ngo -u $user -p $ssh_port -f $ip_file -c "test -f $ver_path && cat $ver_path | grep $commit_id | wc -l"
}


#check 443 1688 port
function psd.check.port() {
	./gsh -n $ngo -u $user -p $ssh_port -f $ip_file -c "netstat -nlt | grep -E \"80|1936\" | wc -l"
}

#check logtail
function psd.check.logtail() {
    ./gsh -n $ngo -u $user -p $ssh_port -f $ip_file -c "ps -ef | grep logtail | grep -v grep | wc -l"
}

function psd.check.disk(){
    ./gsh -n $ngo -u $user -p $ssh_port -f $ip_file -c "df -h | grep "/dev/vdb" |wc -l"   
}

function check.result() {
    fails=$1
    msg=$2
    if [ "$fails" != "" ]; then
        echo "[✗] $msg"
        echo -e "${fails}"
        exit 1
    fi

    echo "[✓] $msg"
}

function psd.check.all() {
    arg=$1

    #################################################################
    #echo "checking version..."
    psd.check.version > $out/vcheck.log

    fails=`cat $out/vcheck.log | grep -v "^nip" | grep -v "=> 1"`
    check.result "$fails" "check version"

    #################################################################
    #echo "checking port..."
    psd.check.port    | grep -v "^nip" > $out/pcheck.log

    fails=`cat $out/pcheck.log | grep -v "^nip" | grep -v "=> 2"`
    check.result "$fails" "check port"

    #################################################################
    #echo "checking logtail..."
    psd.check.logtail | grep -v "^nip" > $out/logcheck.log

    fails=`cat $out/logcheck.log | grep -v "^nip" | grep -v "=> 2"`
    check.result "$fails" "check ilogtail"

    #################################################################
    #echo "checking cloud disk..."
    psd.check.disk | grep -v "^nip" > $out/diskcheck.log

    fails=`cat $out/diskcheck.log | grep -v "^nip" | grep -v "=> 1"`
    check.result "$fails" "check cloud disk"
    echo "[✓] all success"
}

narg=$#
testcase=all
if (( $narg > 0 )); then
    testcase=$1
fi

echo "commit: $commit_id"
echo "    ip: $ip_file"
echo "ip num: `wc -l $ip_file | cut -f1 -d ' '`"
echo "-----------------------"

case $testcase in
    -h)
        show.help
    ;;
    -v)
        echo "checking poseidon version..."
        psd.check.version
    ;;
    -p)
        echo "checking poseidon 1433,1688 port..."
        psd.check.port
    ;;
    -log)
        echo "checking ilogtail process..."
        psd.check.logtail
    ;;
    -disk)
        echo "checking cloud disk..."
        psd.check.disk
    ;;
    *)
        echo "checking all case..."
        psd.check.all
    ;;
esac
