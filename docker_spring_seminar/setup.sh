#!/bin/bash
# ==========================================================
# 第2章：演習の準備
# ==========================================================
# ------------------------------
# 2-5. AWS CLIのインストール
# ------------------------------
# ①AWS CLIのインストール
#公式サイトからインストーラーのダウンロード
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

#解凍用のzipコマンドのインストール
sudo apt install unzip

#zipファイルの解凍
unzip awscliv2.zip

#CLIのインストール
sudo ./aws/install

#インストールの確認
aws --version

#④AWS CLIでAWSへログイン
aws configure

# ==========================================================
# アクセスキーの入力を求められるので、先ほどコピーした内容を元に次の通りに入力ください。
# AWS Access Key ID [None]:アクセスキーIDを入力
# AWS Secret Access Key [None]:シークレットアクセスキーを入力
# Default region name [None]: 「ap-northeast-1」
# Default output format [None]: 「json」
# ==========================================================

# ==========================================================
# 第3章：Spring環境をDockerで構築
# ==========================================================
#ディレクトリの移動
cd /mnt/c/docker_spring_seminar/chapter03

#コンテナの起動
docker-compose up -d --build

#コンテナの起動確認
docker ps -a

#無事にspring-appが起動できていれば不要
docker-compose start spring-app

#コンテナの停止
docker stop spring-app
docker stop phpmyadmin
docker stop mariadb-db

#コンテナの削除
docker rm spring-app
docker rm phpmyadmin
docker rm mariadb-db


# ==========================================================
# 第4章：Spring環境をECSでAWS上に構築
# ==========================================================
# ------------------------------
# 4-1. ECRの環境準備
# ------------------------------
# ------------------------------
# ⓪事前準備
# ------------------------------
# ユーザー名を変数に格納
# 氏名（例: Yamada）
USER_NAME="<氏名>" 
# 日付（例: 1019）
DATE="<日付>" 
USER_NAME_DATE="${USER_NAME}-${DATE}" 

#リージョンを変数に格納 （※デプロイするリージョンに合わせて修正してください）
REGION="ap-northeast-1" 

#アカウントIDの指定
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

#作成するECR名の登録
JAVA_REPO_NAME="ecr-java-${USER_NAME_DATE}"
PMA_REPO_NAME="ecr-phpmyadmin-${USER_NAME_DATE}" 
Maven_REPO_NAME="ecr-maven-${USER_NAME_DATE}"
JDK_REPO_NAME="ecr-jdk-${USER_NAME_DATE}"


# ECRへのログイン
aws ecr get-login-password --region ${REGION} | \
docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

#作業ディレクトリへ移動
cd /mnt/c/docker_spring_seminar/chapter04

# ------------------------------
# ① ECRの作成
# ------------------------------
# Java専用のECRを作成する
aws ecr create-repository --repository-name ${JAVA_REPO_NAME} --region ${REGION}

# phpMyAdmin専用のECRを作成する
aws ecr create-repository --repository-name ${PMA_REPO_NAME} --region ${REGION}

# Maven専用のECRを作成する
aws ecr create-repository --repository-name ${Maven_REPO_NAME} --region ${REGION}

# JDK専用のECRを作成する
aws ecr create-repository --repository-name ${JDK_REPO_NAME} --region ${REGION}



# ------------------------------
# ② Dockerイメージのプル
# ------------------------------
#phpMyAdminイメージのプル
docker pull phpmyadmin/phpmyadmin:5.2.1

#Mavenイメージのプル
docker pull maven:3.9.6-eclipse-temurin-17

#JDKイメージのプル
docker pull eclipse-temurin:17-jdk-alpine

# ------------------------------
# ③ phpMyAdminイメージのプッシュ
# ------------------------------
# phpMyAminイメージをECRへタグ付け
docker tag phpmyadmin/phpmyadmin:5.2.1 ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PMA_REPO_NAME}:5.2.1

# phpMyAdminイメージのプッシュ
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PMA_REPO_NAME}:5.2.1

# ==========================================================
# ④ Maven、JDKイメージのプッシュ 
# ==========================================================
# MavenイメージをECRへタグ付け
docker tag maven:3.9.6-eclipse-temurin-17 ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${Maven_REPO_NAME}:3.9.6-eclipse-temurin-17

# Mavenイメージのプッシュ
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${Maven_REPO_NAME}:3.9.6-eclipse-temurin-17

# JDKイメージをECRへタグ付け
docker tag eclipse-temurin:17-jdk-alpine ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${JDK_REPO_NAME}:17-jdk-alpine

# JDKイメージのプッシュ
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${JDK_REPO_NAME}:17-jdk-alpine


# ==========================================================
# ⑤ Javaイメージの作成
# ==========================================================
docker build --build-arg ACCOUNT_ID=${ACCOUNT_ID} --build-arg REGION=${REGION} --build-arg ECR_REPO_Maven=${Maven_REPO_NAME} --build-arg ECR_REPO_JDK=${JDK_REPO_NAME} -t ${JAVA_REPO_NAME}:latest ./app

# ==========================================================
# ⑥ Javaイメージのプッシュ
# ==========================================================
#JavaイメージをECRへタグ付け
docker tag ${JAVA_REPO_NAME}:latest ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${JAVA_REPO_NAME}:latest

#Javaイメージのプッシュ
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${JAVA_REPO_NAME}:latest

# ------------------------------
# 4-2. CloudFormationでインフラ環境準備
# ------------------------------
# ------------------------------
# ① 環境変数の設定
# ------------------------------
# ユーザー名を変数に格納
# 氏名（例: Yamada）
USER_NAME="<氏名>" 
# 日付（例: 1019）
DATE="<日付>" 
USER_NAME_DATE="${USER_NAME}-${DATE}" 

#リージョンを変数に格納 （※デプロイするリージョンに合わせて修正してください）
REGION="ap-northeast-1" 

# ------------------------------
# ② 作業ディレクトリの移動
# ------------------------------
cd /mnt/c/docker_spring_seminar/chapter04

# ------------------------------
# ③ CloudFormationでインフラ環境構築
# ------------------------------
aws cloudformation deploy \
  --template-file docker-spring-infra.yaml \
  --stack-name docker-spring-${USER_NAME_DATE} \
  --parameter-overrides UserNameDate=${USER_NAME_DATE} \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region ${REGION}


# ------------------------------
# 4-3. 文字列の置換
# ------------------------------
# ------------------------------
# ① 環境変数の設定
# ------------------------------
#以下、これまで設定したものと同じ値を設定ください。
# 氏名（例: Yamada）
export USER_NAME="<氏名>" 
# 日付（例: 1019）
export DATE="<日付>" 
#リージョンの設定
export REGION="ap-northeast-1" 

# ------------------------------
# ② 置換用の実行ファイルの実行
# ------------------------------
#作業ディレクトリへ移動
cd /mnt/c/docker_spring_seminar/chapter04

#実行ファイルへ実行権限の付与
chmod +x replace_placeholders.sh

#実行ファイルの実行
./replace_placeholders.sh


# ------------------------------
# 4-4. ECSの生成
# ------------------------------
# ------------------------------
# ① タスク定義の登録
# ------------------------------
#作業ディレクトリへ移動
cd /mnt/c/docker_spring_seminar/chapter04

# タスク定義の登録
aws ecs register-task-definition --cli-input-json file://taskdef.json


# ------------------------------
# ② 環境変数の設定
# ------------------------------
# ユーザー名を変数に格納
# 氏名（例: Yamada）
USER_NAME="<氏名>" 
# 日付（例: 1019）
DATE="<日付>" 
USER_NAME_DATE="${USER_NAME}-${DATE}" 

#リージョンを変数に格納 （※デプロイするリージョンに合わせて修正してください）
REGION="ap-northeast-1" 

#サブネットIDの取得
SUBNET_A_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-a-subnet-${USER_NAME_DATE}" --query "Subnets[0].SubnetId" --output text)
SUBNET_C_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-c-subnet-${USER_NAME_DATE}" --query "Subnets[0].SubnetId" --output text)

#セキュリティグループIDの取得
ECS_SG_ID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=ecs-sg-${USER_NAME_DATE}" --query "SecurityGroups[0].GroupId" --output text)

#ターゲットグループARNの取得（ELB V2を使用）
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names "java-tg-${USER_NAME_DATE}" --query "TargetGroups[0].TargetGroupArn" --output text)

# --- 確認用表示 ---
echo "Subnet A: $SUBNET_A_ID"
echo "Subnet C: $SUBNET_C_ID"
echo "Security Group: $ECS_SG_ID"
echo "Target Group ARN: $TARGET_GROUP_ARN"

# ------------------------------
# ③ ECSサービスの作成
# ------------------------------
# --- ECSサービス作成コマンド ---
aws ecs create-service \
    --cluster "ecs-cluster-${USER_NAME_DATE}" \
    --service-name "java-service-${USER_NAME_DATE}" \
    --task-definition "task-java-${USER_NAME_DATE}" \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_A_ID,$SUBNET_C_ID],securityGroups=[$ECS_SG_ID],assignPublicIp=DISABLED}" \
    --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=java,containerPort=8080"

# ------------------------------
# 4-5. 動作確認
# ------------------------------
# ------------------------------
# ① phpmyadminでデータの確認
# ------------------------------
TASK_ARN=$(aws ecs list-tasks \
  --cluster ecs-cluster-${USER_NAME_DATE} \
  --service-name phpmyadmin-service-${USER_NAME_DATE} \
  --query 'taskArns[0]' --output text)

ENI_ID=$(aws ecs describe-tasks \
  --cluster ecs-cluster-${USER_NAME_DATE} \
  --tasks $TASK_ARN \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text)

PMA_IP=$(aws ec2 describe-network-interfaces \
  --network-interface-ids $ENI_ID \
  --query 'NetworkInterfaces[0].Association.PublicIp' --output text)

echo "http://"${PMA_IP}

# ------------------------------
# ① ブラウザから動作確認
# ------------------------------

#ロードバランサーのDNS名の取得
java_alb_dns=$(aws elbv2 describe-load-balancers \
    --names alb-${USER_NAME_DATE} \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

#アクセスするURLの取得
URL="http://"${java_alb_dns}

#URLの表示
echo "URLにアクセス:"${URL}



# ------------------------------
# 第5章：リリースの削除
# ------------------------------
# ------------------------------
# 5-1. 共通の環境変数の設定
# ------------------------------
#ユーザ名の指定
# 氏名（例: TaroYamada ※半角英字）
USER_NAME="<氏名>" 
# 日付（例: 1019）
DATE="<日付>" 
USER_NAME_DATE="${USER_NAME}-${DATE}" 
#リージョンの指定
REGION=ap-northeast-1

# ------------------------------
# 5-2. ECSの削除
# ------------------------------
#① ECSの削除
#phpMyAdmin用のECSサービスの削除
aws ecs delete-service \
  --cluster ecs-cluster-${USER_NAME_DATE} \
  --service phpmyadmin-service-${USER_NAME_DATE} \
  --force \
  --region ${REGION}

#Java用のECSサービスの削除
aws ecs delete-service \
  --cluster ecs-cluster-${USER_NAME_DATE} \
  --service java-service-${USER_NAME_DATE} \
  --force \
  --region ${REGION}

#ECSクラスターの削除
aws ecs delete-cluster \
  --cluster ecs-cluster-${USER_NAME_DATE} \
  --region ${REGION} 

# ------------------------------
# 5-4. ALB / Target Groupの削除
# ------------------------------
# ① ALB(ロードバランサー)の削除
# ロードバランサー名の取得
ALB_NAME="alb-${USER_NAME_DATE}"

# ロードバランサーARNの取得
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names "${ALB_NAME}" \
  --query "LoadBalancers[0].LoadBalancerArn" \
  --output text --region ${REGION} 2>/dev/null || true)

#ロードバランサーの削除
aws elbv2 delete-load-balancer --load-balancer-arn "${ALB_ARN}" --region ${REGION}

# ② ターゲットグループの削除
#ターゲットグループ名の取得
TG_ARN=$(aws elbv2 describe-target-groups \
  --names "java-tg-${USER_NAME_DATE}" \
  --query "TargetGroups[0].TargetGroupArn" \
  --output text 2>/dev/null || true)

#ターゲットグループの削除
aws elbv2 delete-target-group --target-group-arn "${TG_ARN}" --region ${REGION}

# ------------------------------
# 5-5. CloudFormationスタックの削除
# ------------------------------
aws cloudformation delete-stack \
  --stack-name docker-spring-${USER_NAME_DATE} \
  --region ${REGION}

# ==========================================================
# 第6章
# ==========================================================
# ------------------------------
# 6-1. Gitのインストール
# ------------------------------
#① Gitのインストール状況の確認
git --version

#② Gitのインストール
#パッケージ管理システムの更新
sudo apt update

#Gitのインストール
sudo apt install git

#③ Gitユーザー情報の初期設定
#メールアドレスの設定
#""内には、ご自身のGitHubで使用するメールアドレスを設定ください。
git config --global user.email "<GitHub上のメールアドレス>"

#名前の設定
#""内には、ご自身のGitHubでのユーザー名を設定ください。
git config --global user.name "<GitHubでのユーザー名>"

# ------------------------------
# 6-3. ローカル・GitHub間のSSH接続
# ------------------------------
# ① 秘密鍵・公開鍵の生成
#「~./ssh」ディレクトリの作成と移動
mkdir ~/.ssh

#「~./ssh」ディレクトリへの移動
cd ~/.ssh

#秘密鍵・公開鍵の作成
# ※ パスフレーズ入力を求められますが無視してエンター3回
ssh-keygen -t rsa

#秘密鍵・公開鍵の作成状況を確認する
ls

#公開鍵の内容を確認する
# ※後ほど利用するので出力内容をコピーする
cat ~/.ssh/id_rsa.pub

# ② GitHubへの公開鍵の設定
#「https://github.com/settings/ssh/new」アクセスし、コピーした内容を貼り付け「ADD SSH KEYをクリック」



# ------------------------------
# 第7章：Spring環境のCI/CD構築
# ------------------------------
# ------------------------------
# 7-1. CloudFormationでインフラ環境準備
# ------------------------------
# ------------------------------
# ① 環境変数の設定
# ------------------------------
# ユーザー名を変数に格納
# 氏名（例: Yamada）
USER_NAME="<氏名>" 
# 日付（例: 1019）
DATE="<日付>" 
USER_NAME_DATE="${USER_NAME}-${DATE}" 

#リージョンを変数に格納 （※デプロイするリージョンに合わせて修正してください）
REGION="ap-northeast-1" 

GITHUB_USER="<GITHUB_USER>"

# ------------------------------
# ② 作業ディレクトリの移動
# ------------------------------
cd /mnt/c/docker_spring_seminar/chapter07

# ------------------------------
# ③ CloudFormationでインフラ環境構築
# ------------------------------
aws cloudformation deploy \
  --template-file docker-spring-infra.yaml \
  --stack-name docker-spring-${USER_NAME_DATE} \
  --parameter-overrides UserNameDate=${USER_NAME_DATE} GithubUser=${GITHUB_USER} \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region ${REGION}

# ------------------------------
# 7-2. 文字列の置換
# ------------------------------
# ------------------------------
# ① 環境変数の設定
# ------------------------------
#以下、これまで設定したものと同じ値を設定ください。
# 氏名（例: Yamada）
export USER_NAME="<氏名>" 
# 日付（例: 1019）
export DATE="<日付>" 
#リージョンの設定
export REGION="ap-northeast-1" 

#GITHUBユーザーの設定
export GITHUB_USER="<GITHUB_USER>"

# ------------------------------
# ② 置換用の実行ファイルの実行
# ------------------------------
#作業ディレクトリへ移動
cd /mnt/c/docker_spring_seminar/chapter07

#実行ファイルへ実行権限の付与
chmod +x replace_placeholders.sh

#実行ファイルの実行
./replace_placeholders.sh

# ------------------------------
# 7-3. CodeDeployの準備 
# ------------------------------
#① 環境変数の設定
#ユーザ名の指定
# 氏名（例: TaroYamada ※半角英字）
USER_NAME="<氏名>" 
# 日付（例: 1019）
DATE="<日付>" 
USER_NAME_DATE="${USER_NAME}-${DATE}" 
#リージョンの指定
REGION=ap-northeast-1

# ② 作業ディレクトリの移動
cd /mnt/c/docker_spring_seminar/chapter07

#③ CodeDeployアプリケーションの作成
aws deploy create-application \
  --application-name cicd-aws-codedeploy-java-${USER_NAME_DATE} \
  --compute-platform ECS \
  --region ${REGION}


#③ CodeDeploy Groupの作成
aws deploy create-deployment-group \
  --cli-input-json file://docker-spring/CodeDeploy/tg-pair.json \
  --region ${REGION}

# ------------------------------
# 7-4. GitHubとローカルの連携
# ------------------------------
#⓪ 環境変数の設定 
GITHUB_USER="<GITHUB_USER>"

#① Javaリポジトリをローカル環境にクローン
# Java用のディレクトリの作成
mkdir -p /mnt/c/docker-spring-seminar
#Java用のディレクトリに移動
cd /mnt/c/docker-spring-seminar

#Javaリポジトリをローカル環境にクローン
echo "# docker-spring-seminar" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin git@github.com:${GITHUB_USER}/docker-spring-seminar.git
git push -u origin main


#② CI/CD関連のファイルのコピー
#文字コードをLFに固定する
sudo apt update
sudo apt install dos2unix
dos2unix /mnt/c/docker_spring_seminar/chapter07/docker-spring/CodeDeploy/appspec.yml
#CI/CD関連のファイルのコピー
cp -r /mnt/c/docker_spring_seminar/chapter07/docker-spring/. /mnt/c/docker-spring-seminar

# ③ GitHubへプッシュ
git add .
git commit -m "Add initial project files for CI/CD setup"
git push origin main

# ------------------------------
# 7-5. 動作確認
# ------------------------------
#① Workflowの状況確認
#  ブラウザ上で、GitHub Actions Successを確認する

# ② ブラウザからの動作確認
#ロードバランサーのDNS名の取得
java_alb_dns=$(aws elbv2 describe-load-balancers \
    --names alb-${USER_NAME_DATE} \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

#アクセスするURLの取得
URL="http://"${java_alb_dns}

#URLの表示
echo "URLにアクセス:"${URL}

#③ 継続的デプロイの確認
#③-1 index.htmlの修正 9行目に「<p>継続的デプロイの追加</p>」に変更

#③-2 GITHUBへのプッシュ
cp -r /mnt/c/docker_spring_seminar/chapter07/docker-spring/. /mnt/c/docker-spring-seminar

git add .
git commit -m "Add initial project files for CI/CD setup"
git push origin main

#③-3 GitHubActionsの成功を確認する
#ブラウザ上で、GitHub Actions Successを確認する

#③-4 動作確認
#ロードバランサーのDNS名の取得
java_alb_dns=$(aws elbv2 describe-load-balancers \
    --names alb-${USER_NAME_DATE} \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

#アクセスするURLの取得
URL="http://"${java_alb_dns}

#URLの表示
echo "URLにアクセス:"${URL}

# ------------------------------
# 第8章：リリースの削除
# ------------------------------
# ------------------------------
# 8-1. 共通の環境変数の設定
# ------------------------------
#ユーザ名の指定
# 氏名（例: TaroYamada ※半角英字）
USER_NAME="<氏名>" 
# 日付（例: 1019）
DATE="<日付>" 
USER_NAME_DATE="${USER_NAME}-${DATE}" 
#リージョンの指定
REGION=ap-northeast-1

# ------------------------------
# 8-2. CodeDeployの削除
# ------------------------------
# グループ名を取得
DG_NAME="cicd-aws-codedeploy-java-group"
APP_NAME="cicd-aws-codedeploy-java-${USER_NAME_DATE}"

#CodeDeployグループの削除
aws deploy delete-deployment-group \
  --application-name ${APP_NAME} \
  --deployment-group-name ${DG_NAME} \
  --region ${REGION} || echo "Deployment group not found"

#CodeDeployアプリケーションの削除
aws deploy delete-application \
  --application-name ${APP_NAME} \
  --region ${REGION} || echo "CodeDeploy application not found"

# ------------------------------
# 8-3. ECS、ECRの削除
# ------------------------------
#① ECSの削除
#phpMyAdmin用のECSサービスの削除
aws ecs delete-service \
  --cluster ecs-cluster-${USER_NAME_DATE} \
  --service phpmyadmin-service-${USER_NAME_DATE} \
  --force \
  --region ${REGION}

#Java用のECSサービスの削除
aws ecs delete-service \
  --cluster ecs-cluster-${USER_NAME_DATE} \
  --service java-service-${USER_NAME_DATE} \
  --force \
  --region ${REGION}

#ECSクラスターの削除
aws ecs delete-cluster \
  --cluster ecs-cluster-${USER_NAME_DATE} \
  --region ${REGION} 



#② ECRの削除
#phpMyAdmin用のECRの削除
aws ecr delete-repository \
  --repository-name ecr-phpmyadmin-${USER_NAME_DATE} \
  --force \
  --region ${REGION} || echo "ECR ecr-phpmyadmin-${USER_NAME_DATE} not found"

#Java用のECRの削除
aws ecr delete-repository \
  --repository-name ecr-java-${USER_NAME_DATE} \
  --force \
  --region ${REGION} || echo "ECR ecr-java-${USER_NAME_DATE} not found"

#Maven用のECRの削除
aws ecr delete-repository \
  --repository-name ecr-maven-${USER_NAME_DATE} \
  --force \
  --region ${REGION} || echo "ECR ecr-maven-${USER_NAME_DATE} not found"

#JDK用のECRの削除
aws ecr delete-repository \
  --repository-name ecr-jdk-${USER_NAME_DATE} \
  --force \
  --region ${REGION} || echo "ECR ecr-jdk-${USER_NAME_DATE} not found"

# ------------------------------
# 8-4. ALB / Target Groupの削除
# ------------------------------
# ① ALB(ロードバランサー)の削除
# ロードバランサー名の取得
ALB_NAME="alb-${USER_NAME_DATE}"

# ロードバランサーARNの取得
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names "${ALB_NAME}" \
  --query "LoadBalancers[0].LoadBalancerArn" \
  --output text --region ${REGION} 2>/dev/null || true)

#ロードバランサーの削除
aws elbv2 delete-load-balancer --load-balancer-arn "${ALB_ARN}" --region ${REGION}

# ② ターゲットグループの削除
#Blue ターゲットグループ名の取得
TG_ARN_BLUE=$(aws elbv2 describe-target-groups \
  --names "java-blue-tg-${USER_NAME_DATE}" \
  --query "TargetGroups[0].TargetGroupArn" \
  --output text 2>/dev/null || true)

#Blueターゲットグループの削除
aws elbv2 delete-target-group --target-group-arn "${TG_ARN_BLUE}" --region ${REGION}

#Green ターゲットグループ名の取得
TG_ARN_GREEN=$(aws elbv2 describe-target-groups \
  --names "java-green-tg-${USER_NAME_DATE}" \
  --query "TargetGroups[0].TargetGroupArn" \
  --output text 2>/dev/null || true)

#Greenターゲットグループの削除
aws elbv2 delete-target-group --target-group-arn "${TG_ARN_GREEN}" --region ${REGION}



# ------------------------------
# 8-5. CloudFormationスタックの削除
# ------------------------------
aws cloudformation delete-stack \
  --stack-name docker-spring-${USER_NAME_DATE} \
  --region ${REGION}


