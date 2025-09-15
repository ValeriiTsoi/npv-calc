package com.example.npvcalc.controller;

import com.example.npvcalc.dto.*;
import com.example.npvcalc.entity.*;
import com.example.npvcalc.service.*;
import jakarta.validation.*;
import java.util.*;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {
  private final AuthService authService;

  public AuthController(AuthService a) {
    this.authService = a;
  }

  @PostMapping("/login")
  public ResponseEntity<?> login(@Valid @RequestBody LoginRequest req) {
    Optional<UserToken> t = authService.login(req.getUsername(), req.getPassword());
    if (t.isEmpty()) return ResponseEntity.status(401).body("Invalid credentials");
    UserToken ut = t.get();
    return ResponseEntity.ok(new TokenResponse(ut.getToken(), ut.getExpiresAt()));
  }
}
