package com.example.npvcalc.controller;

import com.example.npvcalc.dto.*;
import com.example.npvcalc.entity.*;
import com.example.npvcalc.service.*;
import java.time.*;
import java.util.*;
import org.springframework.format.annotation.*;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
public class NpvController {
  private final NpvService s;

  public NpvController(NpvService s) {
    this.s = s;
  }

  @GetMapping("/npv")
  public ResponseEntity<?> getNpv(
      @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
      @RequestParam String symbol) {
    Optional<NpvValue> v = s.findStored(date, symbol);
    if (v.isEmpty()) return ResponseEntity.status(404).body("NPV not found for date/symbol");
    NpvValue x = v.get();
    return ResponseEntity.ok(
        new NpvResponse(
            x.getValuationDate(), x.getSymbol(), x.getNpv(), "db", x.getCalculatedAt()));
  }
}
