# Sylvamo Manufacturing Data Model
## A Guide for Business Stakeholders

---

## What This Model Captures

The Sylvamo Manufacturing Data Model tracks **paper production from raw materials to customer delivery**, enabling:

- **Traceability**: Know exactly which equipment made each roll, from which reel, shipped in which package
- **Quality Management**: Link quality test results to specific reels and rolls
- **Cost Analysis**: Track material costs and price variances by product
- **Inter-Plant Logistics**: Follow packages between Eastover Mill and Sumpter Facility

---

## The Data Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        SYLVAMO PAPER PRODUCTION                         │
└─────────────────────────────────────────────────────────────────────────┘

   🏭 WHERE                    📦 WHAT                     🚚 WHERE TO
   ─────────                   ────────                    ──────────
   
   ┌─────────────┐            ┌─────────────┐
   │   ASSET     │            │  PRODUCT    │
   │             │            │ DEFINITION  │
   │ Eastover    │            │             │
   │ Mill        │            │ Bond 20lb   │
   │             │            │ Offset 50lb │
   └──────┬──────┘            └──────┬──────┘
          │                          │
          │ contains                 │ specifies
          ▼                          ▼
   ┌─────────────┐            ┌─────────────┐
   │  EQUIPMENT  │───────────▶│    REEL     │
   │             │  produces  │   (Batch)   │
   │ PM1, PM2    │            │             │
   │ Winder      │            │ EM001...    │
   └─────────────┘            └──────┬──────┘
                                     │
                                     │ cut into
                                     ▼
                              ┌─────────────┐         ┌─────────────┐
                              │    ROLL     │────────▶│   PACKAGE   │
                              │ (Material   │ bundled │             │
                              │    Lot)     │   in    │ EME12G...   │
                              │             │         │             │
                              │ EME13B...   │         │ Eastover →  │
                              └──────┬──────┘         │ Sumpter     │
                                     │                └─────────────┘
                                     │ tested by
                                     ▼
                              ┌─────────────┐
                              │  QUALITY    │
                              │  RESULT     │
                              │             │
                              │ Caliper ✓   │
                              │ Moisture ✓  │
                              │ Brightness ✓│
                              └─────────────┘
```

---

## Entity Descriptions

### 🏭 Organizational

| Entity | What It Represents | Examples |
|--------|-------------------|----------|
| **Asset** | Physical locations - mills, facilities, warehouses | Eastover Mill, Sumpter Facility |
| **Equipment** | Production machinery within an asset | Paper Machine 1 (PM1), Winder 1, Sheeter |

### 📦 Production (ISA-95/88 Standard)

| Entity | What It Represents | Examples |
|--------|-------------------|----------|
| **ProductDefinition** | Paper grade specifications | Bond 20lb, Offset 50lb, Cover 80lb |
| **Recipe** | How to make a product on specific equipment | "Bond 20lb Master Recipe for PM1" |
| **Reel** | A batch of paper produced (parent reel) | EM0010110008 - 2,500 kg reel |
| **Roll** | Cut rolls from a reel (sellable units) | EME13B08061N - 8.5" width roll |

### 🚚 Logistics

| Entity | What It Represents | Examples |
|--------|-------------------|----------|
| **Package** | Bundle of rolls for inter-plant transfer | EME12G04152F: Eastover → Sumpter |

### 🔬 Quality

| Entity | What It Represents | Examples |
|--------|-------------------|----------|
| **QualityResult** | Test measurements on reels/rolls | Caliper: 4.05 mils (Pass) |

### 💰 Cost

| Entity | What It Represents | Examples |
|--------|-------------------|----------|
| **MaterialCostVariance** | Purchase price variance for raw materials | Wood Softwood: -$72,630 (favorable) |

---

## How to Read the Relationships

| When you see... | It means... |
|-----------------|-------------|
| Asset → Equipment | An asset (mill) **contains** equipment |
| Equipment → Reel | Equipment **produces** reels |
| Reel → Roll | A reel is **cut into** rolls |
| Roll → Package | Rolls are **bundled in** a package |
| Roll → QualityResult | Rolls are **tested by** quality checks |
| Package → Asset (source/dest) | Packages move **between** assets |

---

## Real Example: Tracing a Roll

**Question**: "Where did roll EME13B08061N come from and where is it going?"

**Answer** (traced through the model):

```
Roll: EME13B08061N
  │
  ├── Cut from Reel: EM0010110008
  │     │
  │     ├── Product: Wove Paper 20lb
  │     │
  │     └── Made on: Paper Machine 1 (PM1)
  │           │
  │           └── Located at: Eastover Mill
  │
  ├── Quality Tests: ✓ Caliper (4.05), ✓ Moisture (4.8%), ✓ Brightness (92.5%)
  │
  └── Shipped in Package: EME12G04152F
        │
        ├── From: Eastover Mill
        └── To: Sumpter Facility
```

---

## Business Questions This Model Answers

### Production
- "Which equipment produced the most reels this month?"
- "What's the average reel weight by product grade?"

### Quality
- "Which reels failed quality tests?"
- "What's the pass rate for Caliper tests on PM1?"

### Logistics
- "How many packages are in transit to Sumpter?"
- "What's the average time from ship to receive?"

### Cost
- "Which raw materials have the highest PPV impact?"
- "How has wood pulp pricing changed period-over-period?"

---

## Glossary

| Term | Definition |
|------|------------|
| **Reel** | A large roll of paper as it comes off the paper machine (the "batch") |
| **Roll** | A smaller roll cut from a reel, ready for shipping or further processing |
| **Package** | A bundle of rolls wrapped together for shipping |
| **PPV** | Purchase Price Variance - difference between actual and standard cost |
| **ISA-95** | International standard for manufacturing operations management |
| **ISA-88** | International standard for batch process control (recipes) |

---

*Last updated: January 28, 2026*
*Data Model Version: sylvamo_manufacturing v9*
