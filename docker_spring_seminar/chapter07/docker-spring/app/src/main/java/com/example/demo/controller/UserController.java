package com.example.demo.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.example.demo.service.UserService;

@Controller
public class UserController {

    private final UserService service;

    public UserController(UserService service) {
        this.service = service;
    }

    @GetMapping("/")
    public String index(Model model) {
        System.out.println("test");
        // 1. 一度変数に入れる（Listなどの型はserviceの戻り値に合わせてください）
        var users = service.findAll();

        // 2. コンソールに出力
        System.out.println("DEBUG: usersの中身 = " + users);

        // 3. モデルに追加
        model.addAttribute("users", users);

        return "index";
    }
}