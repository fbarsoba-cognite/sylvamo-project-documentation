> **Note:** These materials were prepared for the Sprint 2 demo (Feb 2026) and may contain outdated statistics. Verify current data in CDF.

# Sylvamo CDF Data Model - Demo Script

**Purpose:** Step-by-step walkthrough for live demonstrations during the presentation  
**Environment:** CDF Fusion (sylvamo-dev project)  
**Estimated Demo Time:** 10-15 minutes total

---

## Pre-Demo Checklist

Before the presentation:

- [ ] Log into CDF Fusion: https://az-eastus-1.cognitedata.com
- [ ] Verify you're in the `sylvamo-dev` project
- [ ] Select "Sylvamo MFG Core" location filter
- [ ] Open GraphQL Explorer in a separate tab
- [ ] Have these sample IDs ready:
  - Asset: `floc:0769` (Eastover Mill)
  - Paper Machine: Search for "PM1"
  - Reel number: (get a recent one from search)
  - Roll number: (get one linked to the reel)
- [ ] Close unnecessary browser tabs
- [ ] Turn off notifications/distractions

---

## Demo 1: Location Filter & Basic Search
**For Slide 15: Search Experience**  
**Duration:** 3 minutes

### Setup
Start at the CDF Fusion home page with no location filter selected.

### Script

**Step 1: Show the problem without filtering**

> "First, let me show you CDF without a location filter selected."

1. Click on **Search** in the left navigation
2. Type "Asset" in the category dropdown
3. Show that you see data from multiple spaces/models

> "You can see there's data from different models here. This can be overwhelming and includes things outside our manufacturing model."

**Step 2: Apply the location filter**

> "Now let me apply our location filter."

1. Click the **location filter** icon (globe) in the top bar
2. Select **"Your locations"**
3. Check **"Sylvamo MFG Core"**
4. Click **Apply**

> "Now we're scoped to just our manufacturing data model."

**Step 3: Search for an asset**

> "Let's search for Paper Machine 1."

1. In the search bar, type: `PM1`
2. Click on the **Asset** result for PM1

> "Here's our Paper Machine 1 asset. Notice the properties on the right - name, description, source information."

**Step 4: Show linked data**

> "What makes this powerful is the linked data."

1. Scroll down to see **Related data**
2. Click on **Events** tab
3. Show the list of linked events

> "These are events linked to PM1 - work orders, production events. We didn't manually link these - the transformations created these relationships."

4. Click on **Time Series** tab
5. Show the list of linked time series

> "And here are the PI tags linked to this paper machine. Over 1,600 time series just for PM1."

### Transition
> "Now let me show you how to trace a quality issue."

---

## Demo 2: Quality Traceability
**For Slide 13: Paper Quality Traceability**  
**Duration:** 4 minutes

### Setup
Stay in CDF Fusion Search with location filter active.

### Script

**Step 1: Find a roll**

> "Let's say a customer calls about a specific roll."

1. In the search bar, type a roll number (e.g., `ROL-`)
2. Filter by clicking **Event** or **Roll** category
3. Click on a roll result

> "Here's our roll record. We can see its properties - width, diameter, roll number."

**Step 2: Navigate to parent reel**

> "I want to know which reel this came from."

1. Look for the **reel** relationship in properties or related data
2. Click on the linked reel

> "This roll was cut from reel [number]. Let's look at this reel."

**Step 3: Show reel details**

> "On the reel, we can see production details."

1. Point out: production date, paper machine, grade
2. Show dimensions: weight, width, diameter

> "This was produced on [date] on PM1, grade [X]."

**Step 4: Show quality results**

> "Now the key question: what were the quality test results?"

1. Navigate to related quality results
2. Click on a quality result

> "Here's a caliper test. Result value: [X] inches. isInSpec: true. This passed specification."

3. Show multiple quality tests if available

> "We can see all the tests done on this reel - caliper, moisture, basis weight. A customer quality complaint could be traced right here."

### Transition
> "Let's look at programmatic access through GraphQL."

---

## Demo 3: GraphQL Queries
**For Slide 16: GraphQL Queries**  
**Duration:** 4 minutes

### Setup
Open the GraphQL Explorer in CDF Fusion (separate tab recommended).

### Script

**Step 1: Show the GraphQL Explorer**

> "For programmatic access, we use GraphQL. Let me show you the explorer."

1. Navigate to **Data Management** > **Data Modeling**
2. Click on your data model
3. Click **Explore** or use the GraphQL tab

**Step 2: Simple list query**

> "Let me run a simple query to list reels."

1. Type this query:

```graphql
{
  listReel(limit: 5) {
    items {
      reelNumber
      productionDate
      name
    }
  }
}
```

2. Click **Run**

> "We get back 5 reels with their numbers and production dates. Simple."

**Step 3: Query with relationships**

> "Now let's traverse relationships. I'll get reels with their rolls."

1. Modify the query:

```graphql
{
  listReel(limit: 3) {
    items {
      reelNumber
      productionDate
      asset {
        name
      }
      rolls {
        items {
          rollNumber
          width
        }
      }
    }
  }
}
```

2. Click **Run**

> "Now we're getting the parent asset - which paper machine - and the child rolls. All in one query, no multiple API calls."

**Step 4: Filter query**

> "We can also filter. Let me find reels from the last week."

1. Modify the query:

```graphql
{
  listReel(
    limit: 10
    filter: {
      productionDate: {
        gte: "2026-02-01T00:00:00Z"
      }
    }
  ) {
    items {
      reelNumber
      productionDate
    }
  }
}
```

2. Click **Run**

> "We can filter by date, by paper machine, by any property. This is what powers our dashboards and integrations."

### Transition
> "This same query can be run from Python, JavaScript, or any HTTP client."

---

## Demo 4: Cost Data (Optional)
**For Slide 14: Material Cost & PPV**  
**Duration:** 3 minutes

### Script

**Step 1: Query MaterialCostVariance**

> "Let me show you the cost data."

1. In GraphQL Explorer:

```graphql
{
  listMaterialCostVariance(limit: 10) {
    items {
      material
      materialType
      currentPPV
      priorPPV
      ppvChange
    }
  }
}
```

2. Click **Run**

> "Here's PPV data from SAP. Each material has its current PPV, prior period PPV, and the change."

**Step 2: Filter for significant changes**

> "Let's find materials with significant cost increases."

1. Add a filter:

```graphql
{
  listMaterialCostVariance(
    limit: 10
    filter: {
      ppvChange: { gt: 500 }
    }
  ) {
    items {
      material
      materialType
      ppvChange
    }
  }
}
```

2. Click **Run**

> "These are materials where PPV increased by more than $500. This is actionable data for procurement."

---

## Demo 5: Data Model Structure (Optional)
**For Slide 4: Data Model at a Glance**  
**Duration:** 2 minutes

### Script

**Step 1: Show the data model in CDF**

> "Let me show you the data model structure in CDF."

1. Navigate to **Data Management** > **Data Modeling**
2. Click on **sylvamo_mfg_core** data model

**Step 2: Show views**

> "Here are our 7 core views."

1. Expand the views list
2. Click on **Reel** view

> "Each view shows its properties and relationships. Reel has reelNumber, productionDate, and relationships to Asset and Rolls."

**Step 3: Show containers (optional)**

> "Behind the views are containers that store the actual data."

1. Navigate to containers
2. Show MfgReel container

> "Containers hold the properties. Views expose them with relationships."

---

## Troubleshooting

### If data doesn't appear
- Check location filter is selected
- Verify you're in sylvamo-dev project
- Refresh the page

### If GraphQL query fails
- Check for typos in property names
- Verify the view name matches exactly
- Check that data exists (run without filter first)

### If relationships are missing
- Some older data may not have relationships
- Try a different entity with known relationships

### Backup plan
If live demo fails:
- Use screenshots from the assets folder
- Walk through the query examples verbally
- Offer to demo after the presentation

---

## Sample Data Reference

### Known Good Assets
| Name | External ID | Type |
|------|-------------|------|
| Eastover Mill | floc:0769 | Plant |
| Paper Machine 1 | (search for PM1) | Equipment |
| Paper Machine 2 | (search for PM2) | Equipment |

### Sample Queries Ready to Use

**List assets with files:**
```graphql
{
  listAsset(limit: 5) {
    items {
      name
      externalId
      files {
        items {
          name
          mimeType
        }
      }
    }
  }
}
```

**List events by type:**
```graphql
{
  listEvent(
    limit: 10
    filter: { eventType: { eq: "WorkOrder" }}
  ) {
    items {
      name
      eventType
      sourceId
    }
  }
}
```

**List time series with assets:**
```graphql
{
  listMfgTimeSeries(limit: 5) {
    items {
      name
      unit
      asset {
        name
      }
    }
  }
}
```

---

## Post-Demo

After the demo:
- Clear any test queries
- Return to home screen or summary slide
- Have Q&A slide ready

---

*Demo script for Sylvamo CDF Data Model presentation*
