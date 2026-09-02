# -----------------------------
# Mavenによるビルド
# -----------------------------

# Maven + Java17 が入ったイメージ
FROM maven:3.9.6-eclipse-temurin-17 AS builder

# コンテナ内部の作業ディレクトリ
WORKDIR /app


# pom.xml をコピー
# 依存ライブラリのキャッシュを効かせるため
COPY pom.xml .


# Maven依存ライブラリを先にダウンロード
RUN mvn dependency:go-offline


# ソースコードをコピー
COPY src ./src


# Spring Bootをビルド(jarファイル生成)
RUN mvn clean package -DskipTests



# -----------------------------
# Javaの実行環境
# -----------------------------

# 軽量Javaイメージ
FROM eclipse-temurin:17-jdk-alpine

# 作業ディレクトリ
WORKDIR /app


# Mavenで生成されたjarをコピー
COPY --from=builder /app/target/*.jar app.jar


# Spring Bootのポート
EXPOSE 8080


# コンテナ起動時に実行
ENTRYPOINT ["java", "-jar", "app.jar"]