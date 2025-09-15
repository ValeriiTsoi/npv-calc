package com.example.npvcalc.repository;

import com.example.npvcalc.entity.UserToken;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.*;

public interface UserTokenRepository extends JpaRepository<UserToken, Long> {
  Optional<UserToken> findByTokenAndRevokedFalseAndExpiresAtAfter(String token, OffsetDateTime now);

  Optional<UserToken> findByUsername(String username);
}
