package com.example.npvcalc.repository;

import com.example.npvcalc.entity.NpvValue;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.*;

public interface NpvRepository extends JpaRepository<NpvValue, Long> {
  Optional<NpvValue> findByValuationDateAndSymbol(LocalDate date, String symbol);
}
