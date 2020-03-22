#!/bin/sh

TAG=`date +%s`
echo $TAG

$(aws ecr get-login --no-include-email --region ap-northeast-2)
docker build -t 264594923212.dkr.ecr.ap-northeast-2.amazonaws.com/web:$TAG .
docker push 264594923212.dkr.ecr.ap-northeast-2.amazonaws.com/web:$TAG
