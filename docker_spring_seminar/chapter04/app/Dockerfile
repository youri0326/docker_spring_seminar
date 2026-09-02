# -----------------------------
# ビルド引数を受け取るARGを定義
# -----------------------------
ARG ACCOUNT_ID=default
ARG REGION=ap-northeast-1
ARG ECR_REPO_Maven=default
ARG ECR_REPO_JDK=default

# -----------------------------
# Build Stage
# -----------------------------
FROM ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_Maven}:3.9.6-eclipse-temurin-17 AS builder

# コンテナ内部の作業ディレクトリ
WORKDIR /app

# pom.xml をコピー
# 依存ライブラリのキャッシュを効かせるため
COPY pom.xml .

# Maven依存ライブラリを先にダウンロード
RUN mvn dependency:go-offline

# ソースコードをコピー
COPY src ./src

# Spring Bootをビルド
# jarファイル生成
RUN mvn clean package -DskipTests



# -----------------------------
# Run Stage
# -----------------------------

# 軽量Javaイメージ
FROM ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_JDK}:17-jdk-alpine

# 作業ディレクトリ
WORKDIR /app


# builderステージからjarをコピー
COPY --from=builder /app/target/*.jar app.jar


# Spring Bootのポート
EXPOSE 8080


# コンテナ起動時に実行
ENTRYPOINT ["java", "-jar", "app.jar"]