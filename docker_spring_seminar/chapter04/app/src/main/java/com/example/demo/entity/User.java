package com.example.demo.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    private String email; // 追加

    @Column(name = "created_at", insertable = false, updatable = false, 
        columnDefinition = "TIMESTAMP DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime createdAt; // 追加（DBで自動生成されるため書き込み禁止設定）

    // --- コンストラクタ ---

    // JPA内部で使用するための「引数なし」コンストラクタ（必須！）
    public User() {
    }

    // DataInitializerなどでデータを作るための「引数あり」コンストラクタ
    public User(String name, String email) {
        this.name = name;
        this.email = email;
    }

    // --- Getter / Setter ---
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    
    // --- 追加：ログ出力で見やすくするために必須 ---
    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", email='" + email + '\'' +
                ", createdAt=" + createdAt +
                '}';
    }    
}