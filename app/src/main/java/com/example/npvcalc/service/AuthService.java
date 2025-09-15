package com.example.npvcalc.service;

import com.example.npvcalc.entity.*;
import com.example.npvcalc.repository.*;
import java.time.*;
import java.util.*;
import org.springframework.beans.factory.annotation.*;
import org.springframework.stereotype.*;

@Service
public class AuthService {
  private final LdapService ldapService;
  private final UserTokenRepository tokenRepository;

  @Value("${app.token.ttl-hours:8}")
  private int ttlHours;

  public AuthService(LdapService l, UserTokenRepository r) {
    this.ldapService = l;
    this.tokenRepository = r;
  }

  public Optional<UserToken> login(String username, String password) {
    if (!ldapService.authenticate(username, password)) return Optional.empty();
    String token = UUID.randomUUID().toString();
    OffsetDateTime exp = OffsetDateTime.now().plusHours(ttlHours);
    Optional<UserToken> existing = tokenRepository.findByUsername(username);
    UserToken ut = existing.orElseGet(UserToken::new);
    ut.setUsername(username);
    ut.setToken(token);
    ut.setExpiresAt(exp);
    ut.setRevoked(false);
    tokenRepository.save(ut);
    return Optional.of(ut);
  }

  public Optional<String> validate(String bearerToken) {
    return tokenRepository
        .findByTokenAndRevokedFalseAndExpiresAtAfter(bearerToken, OffsetDateTime.now())
        .map(UserToken::getUsername);
  }
}
