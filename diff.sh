#!/bin/bash

OLD_ROOT_BASE_DIR=$1
NEW_ROOT_BASE_DIR=$2
DBG=$3

OLD_ROOT_DIR=$PWD/$1
NEW_ROOT_DIR=$PWD/$2
PATCH_ROOT_DIR=$PWD/_patch


BASE_PATH=$NEW_ROOT_DIR
#workpath in newdir 
WORK_PATH=$PWD
WORK_PATH_OLD_DIR=$PWD

pushd_cnt=0
popd_cnt=0

function diff_dir()
{
	olddir=$1
	newdir=$2
	echo "----------------------diff_dir----------------------------"
	echo "newdir: $newdir"

	local file_list_new=`ls ${newdir}`
	#now in new work dir path, have to use absolutily path
	local file_list_old=`ls $WORK_PATH_OLD_DIR/$olddir`


	echo "file_list_new:$file_list_new"
	echo "file_list_old:$file_list_old"

	pushd $WORK_PATH/${newdir}
	let pushd_cnt=pushd_cnt+1

	WORK_PATH=$WORK_PATH/$newdir
	WORK_PATH_OLD_DIR=$WORK_PATH_OLD_DIR/$olddir

	echo -e "\033[33m WORK_PATH:$WORK_PATH \033[0m"
	echo -e "\033[33m WORK_PATH_OLD_DIR:$WORK_PATH_OLD_DIR \033[0m"

	for file in $file_list_new;do
		if [ -L $file ];then
			echo -e "\033[33m [LINK] : $file \033[0m"

			let file_exist=0
			for old_f in $file_list_old;do
				echo "old_f: $old_f"
			if [ $file = $old_f ];then
				echo "find file $file"
				file_exist=1;
				break;
			fi
			done
			
			if [ $file_exist = 0 ];then
				echo "$file not exist in old dir"
				mk_patch_link_file $file
			fi
			
		elif [ -f $file ];then
			echo -e "\033[33m [FILE] : ${file} \033[0m"
			let file_exist=0

			for old_f in $file_list_old;do
				echo "old_f: $old_f"
			if [ $file = $old_f ];then
				echo "find file $file"
				file_exist=1;
				diff_file $file
				break;
			fi
			done

			if [ $file_exist = 0 ];then
				echo "$file not exist in old dir"
				mk_patch_file $file
			fi


		elif [ -d $file ];then

			echo -e "\033[33m [DIR]: ${file} \033[0m"
			let file_exist=0
			for old_f in $file_list_old;do
				echo "old_f: $old_f"
			if [ $file = $old_f ];then
				echo "find file $file"
				file_exist=1;
				diff_dir $file $file
				break;
			fi
			done

			if [ $file_exist = 0 ];then
				echo "$file not exist in old dir"
				mk_patch_dir $file
			fi
		fi

	done

	WORK_PATH=${WORK_PATH%/*}
	WORK_PATH_OLD_DIR=${WORK_PATH_OLD_DIR%/*}

	let popd_cnt=popd_cnt+1
	echo "new popd_cnt: $popd_cnt"
	popd

}


function diff_file()
{
	echo "----------------------diff_file----------------------------"
	file_name=$1

	new_file=$WORK_PATH/$file_name

	old_file=$WORK_PATH_OLD_DIR/$file_name
	
	echo "new_file:$new_file"
	echo "old_file:$old_file"

	old_md5=`md5sum "$old_file"|cut -d ' ' -f1`
	echo "old_md5:$old_md5"
	new_md5=`md5sum "$new_file"|cut -d ' ' -f1`
	echo "new_md5:$new_md5"

	if [ "$old_md5" = "$new_md5" ];then
		echo " = "
	else
		mk_patch_file $file_name
	fi
}

function mk_patch_file()
{
	echo "----------------------mk_patch_file----------------------------"
	file_name=$1
	#calc file path
	file_path=''
	if [ "$WORK_PATH" = "$BASE_PATH" ];then
		file_path=''
	else
		base_len=$(expr $(expr $(expr length $BASE_PATH) + 2))
		work_path_len=$(expr length $WORK_PATH)
		file_path=`expr substr $WORK_PATH $base_len $work_path_len`
	fi
	echo "file_path: $file_path"

	if [ -e $PATCH_ROOT_DIR/$file_path ];then
		echo ""
	else
		`mkdir -p $PATCH_ROOT_DIR/$file_path`
	fi

	if [ "$WORK_PATH" = "$BASE_PATH" ];then
		`cp $NEW_ROOT_DIR/$file_name $PATCH_ROOT_DIR/`
	else
		`cp $NEW_ROOT_DIR/$file_path/$file_name $PATCH_ROOT_DIR/$file_path/`
	fi
	
}

function mk_patch_link_file()
{
	echo "----------------------mk_patch_link_file----------------------------"
	file_name=$1
	#calc file path
	file_path=''
	if [ "$WORK_PATH" = "$BASE_PATH" ];then
		file_path=''
	else
		base_len=$(expr $(expr $(expr length $BASE_PATH) + 2))
		work_path_len=$(expr length $WORK_PATH)
		file_path=`expr substr $WORK_PATH $base_len $work_path_len`
	fi
	echo "file_path: $file_path"

	if [ -e $PATCH_ROOT_DIR/$file_path ];then
		echo ""
	else
		`mkdir -p $PATCH_ROOT_DIR/$file_path`
	fi

	if [ "$WORK_PATH" = "$BASE_PATH" ];then
		`cp -P $NEW_ROOT_DIR/$file_name $PATCH_ROOT_DIR/`
	else
		`cp -P $NEW_ROOT_DIR/$file_path/$file_name $PATCH_ROOT_DIR/$file_path/`
	fi
}

function mk_patch_dir()
{
	echo "----------------------mk_patch_dir----------------------------"
	file_name=$1
	#calc file path
	file_path=''
	if [ "$WORK_PATH" = "$BASE_PATH" ];then
		file_path=''
	else
		base_len=$(expr $(expr $(expr length $BASE_PATH) + 2))
		work_path_len=$(expr length $WORK_PATH)
		file_path=`expr substr $WORK_PATH $base_len $work_path_len`
	fi
	echo "file_path: $file_path"

	if [ -e $PATCH_ROOT_DIR/$file_path ];then
		echo ""
	else
		`mkdir -p $PATCH_ROOT_DIR/$file_path`
	fi

	if [ "$WORK_PATH" = "$BASE_PATH" ];then
		`cp $NEW_ROOT_DIR/$file_name $PATCH_ROOT_DIR/ -r`
	else
		`cp $NEW_ROOT_DIR/$file_path/$file_name $PATCH_ROOT_DIR/$file_path/ -r`
	fi
	
}

function help()
{
	echo "./inc_diff.sh <old_dir> <new_dir> [dbg]"
	echo -e "\033[33m [caution]: two dir must in same path! pass the realitate file path! \033[0m"
	echo -e "\033[33m out_put file is _patch; please keep _patch empty; \033[0m"
	echo -e "\033[33m and back your data if _patch is already in current path! \033[0m"
	echo -e "\033[33m this script can't detect this condition: \033[0m"
	echo "1. removed file"
	echo "2. link file point the different file"
	echo "3. new  file and different file is different type;es: file and dir"
}

if [ "$1" = "" -o  "$2" = "" ];then
	help
	exit 1
fi

if [ ! -e $1 -o ! -e $2 ];then
	help
	exit 1
fi

date_start=`date`
if [ "$DBG" = "dbg" ];then
	diff_dir $OLD_ROOT_BASE_DIR $NEW_ROOT_BASE_DIR
else
	echo $(diff_dir $OLD_ROOT_BASE_DIR $NEW_ROOT_BASE_DIR) >/dev/null
fi
date_end=`date`

echo "time start: $date_start"
echo "time end: $date_end"
exit 1


