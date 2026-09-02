package com.example.demo.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.example.demo.entity.User;
import com.example.demo.repository.UserRepository;

@Configuration
public class DataInitializer {

    @Bean
    CommandLineRunner init(UserRepository repo) {
        return args -> {
            System.out.println("--- DataInitializer Checking Data ---"); 
            if (repo.count() == 0) {
                repo.save(new User("Taro Yamada", "taro@example.com"));
                repo.save(new User("Hanako Suzuki", "hanako@example.com"));
            }
        };
    }
}