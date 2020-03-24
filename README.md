# Elastic Kubernetes Service(EKS) Sample Test



***Base Code**: https://github.com/awslabs/amazon-ecs-nodejs-microservices*



## 가정사항

* Amazon Web Service(AWS)에 계정이 있음
* 기본적인 쿠버네티스 API Object를 이해함
* 환경: Cloud9 (AWS IDE)
* Cloud9은 public에 구성하며 Security Group의 TCP 3000 port는 Any로 열어줌



## Cloud9 설정

* IDE 설정 (아래 링크를 참조)

> https://github.com/toule/aws_cdk_basic_sample





## Kubernetes Cluster

* aws [eks cli](https://docs.aws.amazon.com/cli/latest/reference/eks/index.html)혹은 [cloudformation](https://github.com/aws-quickstart/quickstart-amazon-eks)을 활용해서 사용해도 되나 인프라 구성의 편리성을 위해 [eksctl](https://github.com/weaveworks/eksctl)을 활용 (자세한 것은 링크를 참조)

* eksctl install (참고: https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/getting-started-eksctl.html)

  * aws cli upgrade

    ```bash
    pip install awscli --upgrade --user
    ```

  * curl을 사용하여 eksctl install

    ```bash
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    ```

  * 바이너리 파일을 /usr/local/bin으로 옮김

    ```bash
    sudo mv /tmp/eksctl /usr/local/bin
    ```

  * install 확인 (작성시 버전: 0.15.0)

    ```bash
    eksctl version
    ```

    

- 클러스터 및 작업자 노드 생성

```bash
eksctl create cluster --name eks-sample --tags dev=test --region=ap-northeast-2 --nodegroup-name worker --node-private-networking --vpc-nat-mode Single --alb-ingress --node-type t3.medium --nodes 2
```



- 클러스터 확인

```bash
eksctl get cluster
eksctl get nodegroup --cluster eks-sample
```



## 동작 확인

### 설명: 1  번 monolith directory에서 koa framework 동작

```bash
npm install
node server.js
```

- 아래와 같이 동작화면을 확인

![demo](./images/demo.png)

  

## 단순 컨테이너화 확인

### 설명: 2번 container directory의 경우 1번에서 작성한 코드를 그대로 컨테이너화하여 동작

* docker가 제대로 동작하는지 확인

```bash
docker build -t mono:test .
docker run --name="demo-container" -p 8080:3000 mono:test
```

(1번 동작화면과 동일한 화면이 보이면 됨)

* GKE에 구축하기 위해 GCR(Google Container Repository)에 Push

```bash
source imagepush.sh
```

* manifest directory로 이동하여 내 환경(프로젝트 및 이미지 태그)에 맞게 변수 지정

```bash
sed -i '' "s/my_project/$my_project/g" deploy.yaml
sed -i '' "s/TAG/$TAG/g" deploy.yaml
```

(deploy.yaml 파일에 들어가서 내 프로젝트와 이미지가 제대로 변경되었는지 확인 필요하며 현재 구조는 최초의 한번의 환경변수에 대해 치환을 해주는 구조이기에 다음에 수정하여 업데이트 하는 경우에는 수동으로 이미지 태그에 대한 입력이 필요함)

* gke 클러스터에 배포

```bash
kubectl create -f deploy.yaml
kubectl create -f svc.yaml
```

(정상적으로 진행이 된다면 tcp 로드밸런서에 의해 동작함)

* 생성 확인

`kubectl get pods,svc --selector=app=mono`

![mono](./images/mono-component.png)

* Load Balancer 주소 확인

```bash
LB=$(kubectl get svc monosvc -o json | jq -r ".status.loadBalancer.ingress[].ip")
curl -i -L $LB
```

![result](./images/mono-result.png)  

* (4번 진행을 위해) Object 삭제

```bash
kubectl delete -f deploy.yaml
kebectl delete -f svc.yaml
```

## 마이크로 서비스 컨테이너화 확인

### 설명: api 단위로 나누어서 배포 진행 (3번 directory로 들어가면 서비스별로 나눈 것을 확인할 수 있음)

* 이미지 생성 후 GCR에 Push

```bash
source push.sh
```

* manifest directory로 이동하여 내 환경(프로젝트 및 이미지 태그)에 맞게 변수 지정

```bash
source env.sh
```

(deploy.yaml 파일에 들어가서 내 프로젝트와 이미지가 제대로 변경되었는지 확인 필요)

* gke 클러스터에 배포

```bash
kubectl create -f deploy.yaml
kubectl create -f svc.yaml
kubectl create -f ingress.yaml 
```

* 생성 확인

```bash
kubectl get pods,deploy,svc,ingress --selector=app=msa
```

(HTTP(S) Load Balancer의 경우 생성하고 배포하는데 수분이 소요됨)

![msa](./images/msa-component.png)

(정상적으로 진행이 된다면 HTTP 로드밸런서에 의해 동작함)

* Load Balancer 주소 확인

```bash
LB=$(kubectl get ingress ingress-l7 -o json | jq -r ".status.loadBalancer.ingress[].ip")
echo $LB
curl -i -L $LB
```

![result](./images/msa-result.png)



## 정리

* Object 삭제

```bash
kubectl delete -f deploy.yaml
kubectl delete -f svc.yaml
kubectl delete -f ingress.yaml
```

* 클러스터 삭제

```bash
gcloud container clusters delete sample-cluster --zone asia-northeast3-a
```

(혹은 console에서 삭제)
