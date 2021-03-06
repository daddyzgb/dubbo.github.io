#!/bin/bash

# This shell supports quick deployment of dubbo web services
# Assume the system has installed the following dependencies:
#
# ---------------------------------------------------------
#   jekyll      |   https://jekyllrb.com/docs/home/
# ---------------------------------------------------------
#   gitbook     |   http://www.jianshu.com/p/ec1e7d2c76c6
# ---------------------------------------------------------
#   pages-gem   |   https://github.com/github/pages-gem
# ---------------------------------------------------------
#
# email  : zonghai.szh@alibab-inc.com
# date   : 2017-11-27 21:07:00

# Local Server Port
port=8000
# Local Server Host
host=0.0.0.0

base_dir=$(cd `dirname $0`; pwd)
parent_dir=`dirname ${base_dir}`
git_book_dir="${parent_dir}/dubbo.gitbooks.io"

saved_dir=${git_book_dir}

if [ -f "${base_dir}/git_book_list" ]
then
    if [ -d ${git_book_dir} ]
    then

        echo "updating '${base_dir}'"
        # update self code
        git pull

        # ready to update git books
        for book_dir in ${git_book_dir}/*
        do
            if [ -d ${book_dir} ]
            then
                echo "updating '${book_dir}'"
                cd ${book_dir}
                git pull
            fi
        done

    else
        echo "Attempting to create the directory '${git_book_dir}'"
        mkdir ${git_book_dir}
        cd ${git_book_dir}

        # clone github code for books
        for git_book_url in `cat ${base_dir}/git_book_list`
        do
            echo "git clone $git_book_url"
            git clone ${git_book_url}
        done

        cd ${base_dir}
        # first time , we should install jekyll dependency plugin
        echo "run 'bundle install' for '${base_dir}'."
        bundle install

        # install git books dependency plugins
        for book_dir in ${git_book_dir}/*
        do
            if [ -d ${book_dir} ]
            then
                echo "run 'gitbook install' for '${book_dir}'."
                cd ${book_dir}
                gitbook install
            fi
        done

    fi
else
    echo "file '"${base_dir}/git_book_list"' not exist, shell will exit."
    exit $?
fi

# I'm ready to compile and start service
cd ${base_dir}
echo "run 'jekyll build' for '${saved_dir}'"
jekyll build

for book_dir in ${git_book_dir}/*
do
    if [ -d ${book_dir} ]
    then
        echo "run 'gitbook build' for '${book_dir}'."
        gitbook build ${book_dir}
        echo "build done."

        to_dir_name=$(echo ${book_dir} | awk -F \/ '{print $NF}');
        to_dir_path="${base_dir}/_site/${to_dir_name}";

        echo "copying '${book_dir}/_book/ to ${to_dir_path}."
        if [ ! -e "${to_dir_path}" ]
        then
            mkdir ${to_dir_path}
            cp -rf "${book_dir}/_book/." ${to_dir_path}
        fi
        echo "copy done."
    fi
done

# Now, start jekyll server
cd "${base_dir}/_site"
jekyll server --port ${port} --host ${host} --detach
