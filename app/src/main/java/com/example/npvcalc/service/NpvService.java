package com.example.npvcalc.service;

import com.example.npvcalc.entity.*;
import com.example.npvcalc.repository.*;
import java.time.*;
import java.util.*;
import org.springframework.stereotype.*;

@Service
public class NpvService {
  private final NpvRepository repo;

  public NpvService(NpvRepository r) {
    this.repo = r;
  }

  public Optional<NpvValue> findStored(LocalDate date, String symbol) {
    return repo.findByValuationDateAndSymbol(date, symbol);
  }
}
