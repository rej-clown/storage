#!/bin/bash

SOURCES=$1
BUILD_NUMBER=$2

cd $SOURCES

derictories=($(ls -d */))

for dir in "${derictories[@]}"; do
    echo "Dir: ${dir}"

    module_name=$(basename -- "$dir")
    echo "Module name: ${module_name}"

    module=$SOURCES'/'$module_name
    echo "Module: ${module}"

    cd $module
    echo $PWD
    
    zip -r ${module_name}-${BUILD_NUMBER}.zip *
    cp ${module_name}-${BUILD_NUMBER}.zip ../

    cd ../
    echo $PWD
    rm -Rfv $dir
done