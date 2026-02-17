> **Note:** These materials were prepared for the Sprint 2 demo (Feb 2026) and may contain outdated statistics. Verify current data in CDF.

# Sylvamo CDF Data Model - Speaker Notes

**Total Duration:** 60 minutes  
**Format:** ~3 minutes per slide with key talking points

---

## Section 1: Introduction (9 min)

---

### Slide 1: Title Slide
**Time:** 2 minutes

#### Key Points
- Welcome attendees
- Introduce yourself and role
- Set expectations for the session

#### Speaking Script

> "Good morning/afternoon everyone. Thank you for joining today's session on the Sylvamo Manufacturing Data Model.
>
> I'm [Name], and I've been working on implementing Cognite Data Fusion for Sylvamo's manufacturing operations. Today, I'll walk you through how we've built a data model that aligns with industry standards ISA-95 and ISA-88, specifically adapted for paper manufacturing.
>
> This isn't just a theoretical exercise - we have over 365,000 real data nodes from production systems running in this model today. By the end of this session, you'll understand how all the pieces fit together and how this enables new capabilities for Sylvamo."

#### Transition
> "Let me start by giving you an overview of what we'll cover."

---

### Slide 2: Agenda
**Time:** 2 minutes

#### Key Points
- Six main sections
- Mix of architecture and practical demos
- Q&A at the end

#### Speaking Script

> "Here's our agenda for the next 60 minutes:
>
> First, we'll set the business context - why we need this and what problems we're solving.
>
> Then we'll dive into the data model architecture - the entities, relationships, and how they map to industry standards.
>
> After that, we'll look at the data pipeline - how data flows from SAP, PI Server, and other systems into CDF.
>
> We'll cover two key use cases with demonstrations - quality traceability and material cost analysis.
>
> We'll touch on our CI/CD implementation and deployment practices.
>
> And finally, we'll look at the roadmap and what's coming next.
>
> I'll save Q&A for the end, but feel free to ask clarifying questions as we go."

#### Transition
> "So let's start with why this matters for Sylvamo."

---

### Slide 3: Business Context
**Time:** 5 minutes

#### Key Points
- Current challenges with siloed data
- The opportunity unified data presents
- Specific project goals

#### Speaking Script

> "Sylvamo, like many manufacturing organizations, has data spread across multiple systems. SAP handles our ERP and cost data. PI Server captures process variables from the machines. Proficy logs production events. SharePoint stores quality reports. And so on.
>
> The challenge is that these systems don't naturally talk to each other. If a customer calls about a quality issue with a roll of paper, you might need to log into three or four different systems to trace the problem back to production conditions.
>
> Cognite Data Fusion gives us the opportunity to bring all this data together in one place, with relationships that let us navigate naturally from a roll back to its reel, to the paper machine that produced it, to the process conditions at the time.
>
> Our specific goals for this project are:
> - End-to-end traceability from production to customer
> - Quality insights that connect test results to production parameters
> - Cost visibility with Purchase Price Variance analysis
> - And inter-plant tracking as materials move between Eastover and Sumpter
>
> This data model is the foundation that makes all of this possible."

#### Transition
> "Now let's look at how the data model is actually structured."

#### Anticipated Questions
- Q: "Which systems are we starting with?"
- A: "We're live with SAP, PI Server, Proficy, SharePoint, and the PPR system through Microsoft Fabric."

---

## Section 2: Data Model Overview (15 min)

---

### Slide 4: Data Model at a Glance
**Time:** 4 minutes

#### Key Points
- Model evolution journey
- Space and instance structure
- Current scale with real data

#### Speaking Script

> "Let me tell you the story of how this model evolved, because it shows the power of iterative development in CDF.
>
> We started with a Proof of Concept model called `sylvamo_mfg`. It had 9 entities and just 197 sample nodes. This let us validate the ISA-95/ISA-88 alignment with stakeholders before committing to production.
>
> Then we built the production model: `sylvamo_mfg_core`. This is what you're seeing today:
>
> | Component | PoC | Production |
> |-----------|-----|------------|
> | Entities | 9 | 8 views |
> | Nodes | 197 | 450,000+ |
> | Spaces | 1 | 2 (schema + instances) |
> | Transformations | Manual | 24 automated SQL |
>
> The two-space pattern is important. The schema space (`sylvamo_mfg_core_schema`) holds our blueprints - containers and views. The instance space (`sylvamo_mfg_core_instances`) holds the actual data. This separation gives us cleaner access control and easier schema evolution.
>
> All 8 views implement CDM interfaces: Asset implements CogniteAsset, TimeSeries implements CogniteTimeSeries, Event implements CogniteActivity. This wasn't just theoretical compliance - it's what makes Industrial Tools work out of the box. Search, Canvas, InField - they all recognize our entities.
>
> And now we're building `mfg_extended` - the third layer. This adds WorkOrder, Notification, Operation, ProductionOrder, CostEvent. Each iteration adds more capability while staying compatible."

#### Transition
> "Let me show you how these entities relate to each other."

---

### Slide 5: Entity Relationship Diagram
**Time:** 3 minutes

#### Key Points
- Main entity relationships
- Flow from production to delivery
- Bidirectional navigation

#### Speaking Script

> "This is the entity relationship diagram. I know it looks complex at first, but there's a logical flow here.
>
> Start at the top with Asset - this is our organizational hierarchy. Eastover Mill contains areas, which contain production units.
>
> Equipment is linked to Assets. Paper Machine 1 is equipment within the Eastover Mill asset.
>
> Equipment produces Reels. A reel is a batch in ISA-95 terms - it's one continuous production run on the paper machine.
>
> Reels are cut into Rolls. This is where the material lot concept comes in - each roll is a sellable unit.
>
> Rolls can be bundled into Packages for inter-plant shipping.
>
> QualityResult connects to both Reels and Rolls - we test at both levels.
>
> And ProductDefinition tells us what specification the paper should meet - basis weight, grade, and so on.
>
> The beauty of this in CDF is that you can navigate in any direction. Start with a roll, trace back to the reel. Start with an asset, see all the reels it produced."

#### Transition
> "You might be wondering how this maps to industry standards. Let me explain that."

---

### Slide 6: ISA-95/ISA-88 Alignment
**Time:** 4 minutes

#### Key Points
- Architecture Decision Records (ADRs)
- ISA mappings validated by Cognite expert
- Practical vs. theoretical alignment

#### Speaking Script

> "This model isn't just ISA-compliant on paper - we documented every major decision in Architecture Decision Records. Let me share the key ones, which came from working with Johan Stabekk, Cognite's ISA manufacturing expert.
>
> **ADR-1: Use CDM Asset instead of full ISA hierarchy.**
>
> ISA-95 defines Enterprise → Site → Area → ProcessCell → Unit. That's a lot of layers. Johan's guidance was: 'Don't over-engineer. Use CDM Asset with `assetType` annotations.' This keeps us compatible with Industrial Tools while still capturing the hierarchy. We have 44,898 asset nodes in 9 levels from SAP Functional Locations.
>
> **ADR-2: Reel = Batch, Roll = MaterialLot.**
>
> In paper manufacturing, a reel is one continuous production run - that's exactly what ISA-88 calls a Batch. When we cut the reel, each piece becomes a Roll - that's a MaterialLot. This isn't forcing terminology; it's recognizing that paper manufacturing naturally fits ISA-88.
>
> **ADR-3: Package is a Sylvamo extension.**
>
> ISA-88 doesn't have an entity for inter-plant material transfer. But Eastover makes paper that ships to Sumpter for finishing. We needed to track that. So Package is our extension - it links Rolls to shipments with source plant and destination plant.
>
> **ADR-4: Schema/Instance space separation.**
>
> This matches the Cognite ISA Extension pattern. Schema changes require different permissions than data changes. It's cleaner access control.
>
> The takeaway: we aligned where it made sense and extended where we needed to. No dogmatic purity - just practical decisions documented for future maintainers."

#### Transition
> "Let me walk through the specific entities in more detail."

---

### Slide 7: Core Entities - Production
**Time:** 3 minutes

#### Key Points
- Asset hierarchy
- Equipment types
- Recipe structure

#### Speaking Script

> "On the production side, we have three main entities.
>
> Asset represents our organizational hierarchy. We have about 46,000 asset nodes, imported from SAP's Functional Location structure. This includes everything from the plant level down to individual work centers.
>
> Equipment represents the physical machines. Paper Machines PM1 and PM2, winders, sheeters. Each piece of equipment links to its parent Asset.
>
> Recipe captures how we make products. This follows ISA-88's recipe model. A General Recipe defines the abstract process. A Master Recipe is site-specific. Each recipe links to a ProductDefinition - which grade of paper it produces - and to Equipment - which machine runs it.
>
> In the data model, we have target parameters in the recipe - basis weight, moisture targets - that we can compare against actual production values."

#### Transition
> "Now let's look at the material flow side."

---

### Slide 8: Core Entities - Material Flow
**Time:** 3 minutes

#### Key Points
- Reel as the batch
- Roll as material lot
- Quality testing points

#### Speaking Script

> "The material flow is where the real traceability happens.
>
> Reel is our batch entity. We have over 61,000 reels in the system. Each reel has a production date, dimensions, weight, and links to the paper machine that produced it and the product definition it was made to.
>
> When a reel is cut, it becomes multiple Rolls. We have over 100,000 rolls tracked. Each roll knows which reel it came from, its dimensions, and its quality status.
>
> Rolls can be bundled into Packages for shipping. This is critical for inter-plant tracking. A package has a source plant and destination plant, so we can trace where material came from and where it went.
>
> QualityResult captures test results - caliper, moisture, basis weight. The important thing is that quality results link to both reels AND rolls, because we test at both stages. The isInSpec flag tells us immediately if something passed or failed."

#### Transition
> "Now that you understand the model structure, let's see how data actually gets here."

---

## Section 3: Data Pipeline (12 min)

---

### Slide 9: Source Systems
**Time:** 3 minutes

#### Key Points
- Five main data sources
- What each provides
- System owners

#### Speaking Script

> "Data flows into CDF from five main source systems.
>
> SAP ERP is our enterprise system. It provides material master data, cost information including Purchase Price Variance, and work order data. This is owned by Finance and Operations.
>
> The PPR System - Paper Production Reporting - captures reel, roll, and package data. This is the production team's system of record.
>
> Proficy GBDB logs production events as they happen on the floor. Real-time event data from the manufacturing execution system.
>
> PI Server is our historian. Over 3,500 process tags - temperatures, pressures, speeds - from the paper machines. Engineering owns this data.
>
> And SharePoint holds quality reports and documents that the Quality team uploads.
>
> Each of these systems has an owner, and each provides different types of data. CDF brings them together."

#### Transition
> "Let me show you how the integration works."

---

### Slide 10: Integration Architecture
**Time:** 3 minutes

#### Key Points
- Three-layer architecture
- RAW as staging area
- Transformations as the bridge

#### Speaking Script

> "The integration follows a three-layer pattern.
>
> First, extractors pull data from source systems and land it in RAW databases. RAW is like a staging area - it's a copy of the source data in CDF.
>
> We have five extractors running. The Fabric Connector pulls from Microsoft Fabric Lakehouse, where SAP and PPR data lands. The PI Extractor pulls time series directly. We have SharePoint, SAP OData, and SQL extractors for the other sources.
>
> Second, transformations convert RAW data into our data model format. These are SQL queries that run on a schedule - typically hourly. They handle deduplication, data quality checks, and relationship creation.
>
> Third, the data lands in our sylvamo_mfg_core model as nodes that can be queried through GraphQL, Industrial Tools, or the SDK.
>
> The key principle: RAW is raw - we don't modify it. Transformations are where we clean and shape the data."

#### Transition
> "Let me tell you more about the extractors."

---

### Slide 11: Extractors
**Time:** 4 minutes

#### Key Points
- Five extractors with real volumes
- Data ownership patterns
- RAW database naming convention

#### Speaking Script

> "We have five extractors actively running. Let me give you the actual volumes:
>
> **Fabric Connector** - This is our workhorse. It connects to Microsoft Fabric Lakehouse where Sylvamo's data engineering team lands SAP and PPR data. We pull into three RAW databases:
> - `raw_ext_fabric_ppr`: 61K reels, 2.3M rolls, 50K packages
> - `raw_ext_fabric_ppv`: 200 PPV snapshots (cost data)
> - `raw_ext_fabric_sapecc`: 407K work orders from IW28
>
> **PI Extractor** - Connects directly to PI Server (S769PI01, S769PI03). 3,500+ process tags flowing into CDF Time Series. Temperatures, pressures, speeds, reactor levels - all the process variables from the paper machines. Engineering owns this data.
>
> **SharePoint Extractor** - Pulls quality reports from Sumter Shared Documents. 21+ roll quality inspection reports currently. The Quality team uploads these manually.
>
> **SAP OData Extractor** - Real-time connection to SAP Gateway. Business partner details, functional locations, material master, production orders. Owned by Finance and Operations.
>
> **SQL Extractor** - Connects to Proficy GBDB. Production events with lab test results, tag metadata, sample tracking. Manufacturing execution data.
>
> The naming convention is `raw_ext_<extractor>_<source>`. When you see `raw_ext_fabric_ppr`, you know immediately: Fabric extractor, PPR source. This clarity matters when debugging data lineage."

#### Transition
> "Once data is in RAW, transformations move it to the model."

---

### Slide 12: Transformations
**Time:** 3 minutes

#### Key Points
- 24 SQL transformations
- Sample transformation logic
- Schedule and refresh

#### Speaking Script

> "We have 24 SQL transformations running.
>
> Each transformation takes data from one or more RAW tables and writes it to the data model. Let me show you a simplified example.
>
> For reels, we select from raw_ext_fabric_ppr.ppr_hist_reel. We create an externalId by concatenating 'reel:' with the reel number. We map the production date, dimensions, and weight. And critically, we use node_reference to create the relationship to the paper machine asset.
>
> The transformations run on a schedule - most are hourly. For the first load, they processed millions of rows. Now they incrementally update as new data arrives.
>
> One important thing: transformations handle data quality. If a required field is null, we handle it gracefully. If there are duplicates in the source, we dedupe here. The model stays clean."

#### Transition
> "Now let's see this in action with some use cases."

#### Anticipated Questions
- Q: "How long does a transformation take?"
- A: "Initial load was several hours. Incremental runs are typically under a minute."

---

## Section 4: Use Cases (12 min)

---

### Slide 13: Use Case 1 - Paper Quality Traceability
**Time:** 4 minutes

#### Key Points
- Business scenario with real data
- Navigation flow through relationships
- Defect analysis capabilities

#### Speaking Script

> "Let's look at a real use case: quality traceability. And I want to show you actual data from our system.
>
> We currently have over 83,600 reels tracked, with a total weight of 2.8 million pounds - averaging about 57,000 pounds per reel. These are real production runs from Eastover.
>
> Now imagine a customer calls about a quality issue with a roll. In the old world, you'd log into SAP for the production order, PI for process data, SharePoint for quality reports. Maybe 3-4 systems, manual timestamp correlation.
>
> In CDF, you search for the roll. It shows you the parent reel. The reel links to the paper machine asset, the production date, and all quality test results.
>
> Here's real data from our quality tracking: We have 21 quality results loaded, with a 71% pass rate - 15 passed, 6 failed. The defects we're tracking include:
> - Crushed Edge: 2 occurrences
> - Baggy Edge: 2 occurrences  
> - Up Curl: 2 occurrences
>
> Each QualityResult has `testName`, `resultValue`, `specMin`, `specMax`, and critically an `isInSpec` flag. You can immediately see pass/fail without doing math.
>
> And because we've linked PI time series to assets, you can also see what the process conditions were during that production run - temperature, pressure, speed. The 3,532 time series tags from PI are now contextually linked.
>
> This is the power of the graph - navigating relationships instead of hunting through systems."

#### Demo Notes
- Search for a specific roll number
- Show parent reel relationship
- Show quality results with isInSpec flag
- Highlight the defect types (Crushed Edge, Baggy Edge, Up Curl)
- Show linked time series if available

#### Transition
> "The second use case is about cost visibility - and this one has some fascinating data."

---

### Slide 14: Use Case 2 - Material Cost & PPV
**Time:** 4 minutes

#### Key Points
- PPV concept explained
- Real data from SAP
- Business insights from variance analysis

#### Speaking Script

> "The second use case is material cost analysis through Purchase Price Variance, or PPV. Let me show you real data.
>
> PPV measures the difference between what you expected to pay for raw materials versus what you actually paid. Positive PPV means you overpaid. Negative means you got a better deal.
>
> We've loaded real PPV data from SAP via Microsoft Fabric. Here's what it shows by material type:
>
> | Type | Count | Total PPV | Total Cost |
> |------|-------|-----------|------------|
> | Packaging (PKNG) | 102 materials | +$9,254 | $4,403 |
> | Raw Materials (RAWM) | 61 materials | -$23,063 | $6,240 |
> | Fiber (FIBR) | 7 materials | -$104,342 | $1,339 |
>
> That fiber line is interesting - negative $104,000 PPV on just $1,339 cost. Let me drill into that.
>
> The top three materials by PPV impact are all wood and chips:
> - **Softwood**: -$72,630 (we're getting this way below standard cost)
> - **Mixed Hardwood Chips**: -$24,801
> - **Caustic Soda**: -$22,095
>
> In the old world, this was a quarterly finance report. Now it's queryable in real-time through GraphQL:
>
> ```graphql
> listMaterialCostVariance(filter: { ppvChange: { gt: 500 }})
> ```
>
> And because MaterialCostVariance links to ProductDefinition, we can ask: which paper grades are most affected by these cost changes? If softwood prices spike, which products feel it first?
>
> This connects finance data to manufacturing decisions."

#### Transition
> "Let me show you the search experience that ties all of this together."

---

### Slide 15: Search Experience
**Time:** 3 minutes

#### Key Points
- Location filters
- Linked data types
- Navigation in Fusion

#### Speaking Script

> "One of the benefits of building on CDM is the Industrial Tools integration.
>
> When you open CDF Fusion and select the 'Sylvamo MFG Core' location filter, you're scoped to just our data model. Search shows Assets, Events, Files, Time Series - all the data we've ingested.
>
> Search for 'PM1' and you get the Paper Machine 1 asset. On that asset, you can see linked events - production orders, work orders. You can see linked files - P&IDs, equipment drawings. You can see linked time series - all the process tags associated with that machine.
>
> This linking happened through our Sprint 2 work. We mapped Proficy events to assets via the PU_Id field. We mapped work orders via SAP Functional Location. We mapped time series by naming convention.
>
> The end result is: you pick an asset, and you can see everything related to it. No more hunting across systems."

#### Demo Notes
- Show location filter selection
- Search for PM1 asset
- Show linked events
- Show linked time series

#### Transition
> "For programmatic access, we use GraphQL."

---

### Slide 16: GraphQL Queries
**Time:** 3 minutes

#### Key Points
- Query structure
- Traversing relationships
- Access methods

#### Speaking Script

> "For developers and integrations, GraphQL is the primary API.
>
> The query structure follows our data model. You can list reels, filter by date range, and for each reel retrieve its production date, the asset that made it, and drill into its rolls.
>
> What makes this powerful is relationship traversal. In one query, you can go from reel to rolls to quality results. You're not making multiple API calls - the graph does the work.
>
> Access methods: The GraphQL Explorer in CDF is great for ad-hoc queries. For applications, the Python SDK and JavaScript SDK both support GraphQL. There's also a REST API if you prefer that.
>
> We're already using this for reporting. A scheduled query pulls daily production summaries into a Power BI dashboard."

#### Anticipated Questions
- Q: "Can we use this from Power BI directly?"
- A: "Yes, the CDF connector for Power BI supports GraphQL queries."

#### Transition
> "Let's talk about how we deploy all of this."

---

## Section 5: Implementation & CI/CD (6 min)

---

### Slide 17: CI/CD Pipeline
**Time:** 3 minutes

#### Key Points
- Cognite Toolkit CLI
- Environment promotion
- Authentication

#### Speaking Script

> "Everything I've shown you - the data model, transformations, extractors - is deployed through a CI/CD pipeline.
>
> We use the Cognite Toolkit CLI, or cdf-tk. The two main commands are 'cdf-tk build', which validates and compiles your configurations, and 'cdf-tk deploy', which applies them to CDF.
>
> Our pipeline has two stages. On feature branches, we run build and deploy with --dry-run. This shows what WOULD change without actually changing anything. It's great for code review.
>
> When we merge to main, we run the real deploy. Changes go to DEV first, then STAGING with approval, then PRODUCTION with approval.
>
> Authentication uses an Entra ID service principal. The credentials are stored in our CI system's secret store - never in code.
>
> This means our data model is version controlled, reviewed, and deployed automatically. No manual CDF console changes."

#### Transition
> "Let me share some statistics on what we have running today."

---

### Slide 18: Real Data Statistics
**Time:** 3 minutes

#### Key Points
- Detailed entity counts from production
- Data sources mapped to entities
- Growth trajectory

#### Speaking Script

> "Let me give you the exact numbers from production today:
>
> | Entity | Count | Source |
> |--------|-------|--------|
> | Asset | 44,898 | SAP Functional Locations (9 hierarchy levels) |
> | Event | 92,000+ | SAP, Proficy, Fabric |
> | Material | 58,342+ | SAP Material Master |
> | MfgTimeSeries | 3,532 | PI Server (75+ connected) |
> | Reel | 83,600+ | Fabric PPR (2.8M lbs total weight) |
> | Roll | 2,300,000+ | Fabric PPR (from 2.3M raw rows) |
> | RollQuality | 21+ | SharePoint (71% pass rate) |
> | CogniteFile | 97 | Various sources |
> | **TOTAL** | **450,000+** | |
>
> Let me highlight a few things:
>
> The 83,600 reels represent real production runs - averaging 57,000 lbs per reel. That's not sample data; that's actual paper Sylvamo made.
>
> The 2.3 million rolls - every roll cut from those reels is tracked. When a customer asks about roll #12345, we can find it.
>
> The 3,532 time series aren't just numbers - they're linked to assets. PM1 has over 1,600 tags associated with it. You can see process conditions for any production run.
>
> And the 407,000 work orders from SAP IW28 - that's the maintenance history for the plant.
>
> This refreshes hourly. Production at 2pm shows up by 3pm."

#### Transition
> "Let me share what's coming next."

---

## Section 6: Roadmap & Wrap-up (6 min)

---

### Slide 19: Sprint 2 Progress & Roadmap
**Time:** 3 minutes

#### Key Points
- Current sprint work
- Near-term roadmap
- Extended model preview

#### Speaking Script

> "We're currently in Sprint 2, focused on the search experience and contextualization.
>
> We've completed linking Proficy events to assets, work orders to assets, time series to assets, and files to assets. This is what enables the rich search experience I showed earlier.
>
> Still in progress: P&ID contextualization - using AI to identify tags in P&ID drawings and link them to assets.
>
> Coming next: We're building an 'MFG Extended' model. This adds maintenance activity types - Work Orders, Notifications, Operations. It adds production activity types - Production Orders and Production Events from Proficy. And it adds a proper Equipment entity that implements CogniteEquipment.
>
> We're also planning to onboard Sumter as a second location. The model is designed to support multiple plants - we just need to extend the extractors and transformations.
>
> The roadmap is driven by use cases. As Sylvamo identifies new questions they want to answer, we extend the model."

#### Transition
> "Let me wrap up with key takeaways."

---

### Slide 20: Summary & Q&A
**Time:** 3 minutes + Q&A

#### Key Points
- Five key takeaways
- Resources
- Open Q&A

#### Speaking Script

> "To summarize what we've covered:
>
> First, this is a standards-based model. We aligned with ISA-95 and ISA-88 so it's maintainable and extensible.
>
> Second, it's built on CDM - the Cognite Data Model. This gives us compatibility with Industrial Tools out of the box.
>
> Third, we have real data. Over 365,000 nodes from production systems, updated hourly.
>
> Fourth, we've enabled concrete use cases. Quality traceability and cost analysis are working today.
>
> Fifth, we deploy through CI/CD. The model is versioned, reviewed, and automatically deployed.
>
> Resources: The documentation lives in our GitHub repository at the URL shown. You can explore the data yourself in the sylvamo-dev CDF project.
>
> Thank you for your attention. I'm happy to take questions."

#### Anticipated Questions

**Q: How do we add a new data source?**
A: Configure an extractor to land data in RAW, then write transformations to map it to the model. Follow our RAW naming convention.

**Q: Can we use this for other plants?**
A: Yes, the model supports multi-plant. We need to extend extractors and transformations, but the structure is ready.

**Q: What about real-time data?**
A: Time series are near real-time from PI. Other data refreshes hourly. For true real-time, we'd explore streaming transformations.

**Q: Who maintains this?**
A: The data engineering team maintains extractors and transformations. The model schema changes go through PR review.

---

## Presentation Tips

### Timing
- Intro slides can be quicker (2 min each)
- Technical slides may need full 3+ minutes
- Allow flexibility for questions
- Demo slides may run longer

### Pacing
- Slow down for ERD and architecture diagrams
- Give audience time to absorb complex visuals
- Repeat key terms: "reel as batch", "CDM foundation"

### Engagement
- Ask if there are questions after Section 2
- Offer to dive deeper into any area
- Reference specific attendees' domains when relevant

### Backup Material
- Have GraphQL query examples ready
- Have transformation SQL ready to show
- Have CDF Fusion open in another tab

---

## Appendix A: Johan Stabekk's Key Guidance

**Source:** ISA-95 & Sylvamo Data Model Alignment meeting (Jan 28, 2026)  
**Expert:** Johan Stabekk - 6 years paper & pulp experience, 3.5 years at Cognite

### Key Quotes to Reference

**On Simplicity:**
> "We don't want to over complicate it but we don't want to make it so simple that we sit with something that doesn't give them anything."

**On Hierarchy:**
> "Inside of ISA 95 you would want to create an enterprise type, a site type, an area type, a process cell type. **We don't want that. That's over complicating it.** We want an **asset type** and we want an **equipment type** and these two basically."

**On Reel as Batch:**
> "A batch here is a reel and an extension of that batch is a roll."

**On Package Entity:**
> "Here we're trying to go beyond what we have. At IP we are inside of the four walls of a production plant. Here we're going to go **between two production plants**."

**On Scalability:**
> "We start with what we know we can already define... and then we build from there."

---

## Appendix B: Complete Traceability Query

Use this GraphQL query to demonstrate full end-to-end traceability:

```graphql
{
  # Find a specific roll
  getRoll(externalId: "roll:EME13B08061N") {
    rollNumber
    width
    
    # What reel was it cut from?
    reel {
      reelNumber
      productionDate
      
      # What product grade?
      productDefinition {
        name
        basisWeight
      }
      
      # What machine made it?
      equipment {
        name
        asset { name }  # Which mill?
      }
    }
    
    # What package is it in?
    package {
      packageNumber
      status
      sourcePlant { name }       # Shipped from?
      destinationPlant { name }  # Shipped to?
    }
  }
}
```

**Expected Result:**
```json
{
  "rollNumber": "EME13B08061N",
  "width": 8.5,
  "reel": {
    "reelNumber": "EM0010110008",
    "productionDate": "2026-01-15",
    "productDefinition": {
      "name": "Wove Paper 20lb",
      "basisWeight": 20.0
    },
    "equipment": {
      "name": "Paper Machine 1 (PM1)",
      "asset": { "name": "Eastover Mill" }
    }
  },
  "package": {
    "packageNumber": "EME12G04152F",
    "status": "Shipped",
    "sourcePlant": { "name": "Eastover Mill" },
    "destinationPlant": { "name": "Sumpter Facility" }
  }
}
```

---

## Appendix C: Verified Use Case Data Summary

### Use Case 1: PPV Analysis (Real Data)

**Total Materials:** 176  
**Materials with Non-Zero PPV:** 21  
**Total Current PPV:** -$118,151.12 (Net Favorable)

| Type | Count | Total PPV | Total Cost |
|------|-------|-----------|------------|
| PKNG | 102 | +$9,253.79 | $4,403.45 |
| PRD1 | 6 | $0.00 | $186.18 |
| RAWM | 61 | -$23,062.58 | $6,240.13 |
| FIBR | 7 | -$104,342.33 | $1,339.68 |

**Top 3 Materials by PPV Impact:**
1. WOOD, SOFTWOOD (FIBR): -$72,630.80
2. CHIPS, MIXED HARDWOOD (FIBR): -$24,801.74
3. CAUSTIC SODA (RAWM): -$22,095.06

### Use Case 2: Quality Analysis (Real Data)

**Production Data:**
- Reels: 50
- Rolls: 19
- Packages: 50
- Quality Results: 21

**Quality Summary:**
- Pass Rate: 71.4% (15 passed, 6 failed)
- Total Reel Weight: 2,864,026 lbs
- Average Reel Weight: 57,281 lbs

**Defect Distribution:**
- 005 - Crushed Edge: 2 occurrences
- Baggy Edge: 2 occurrences
- Up Curl: 2 occurrences
- 007 - Edge Damage: 1 occurrence
- Collating Box Jams: 1 occurrence

**Business Insight:** Edge-related defects account for 83% of failures (5 of 6). Root cause analysis should focus on winding tension and edge handling.

---

## Appendix D: Data Model Visual Summary

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Eastover Mill│────►│   PM1        │────►│ Reel         │
│   (Asset)    │     │ (Equipment)  │     │ EM0010110008 │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                 │ cut into
                            ┌────────────────────┼────────────────────┐
                            ▼                    ▼                    ▼
                     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
                     │ Roll 061N    │     │ Roll 062N    │     │ Roll 063N    │
                     └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
                            │                    │                    │
                            └────────────────────┼────────────────────┘
                                                 │ bundled in
                                                 ▼
                                          ┌──────────────┐
                                          │ Package      │
                                          │ EME12G04152F │
                                          └──────┬───────┘
                                                 │
                              ┌──────────────────┴──────────────────┐
                              ▼                                     ▼
                       ┌──────────────┐                      ┌──────────────┐
                       │ Eastover Mill│                      │Sumpter Facil.│
                       │ (sourcePlant)│                      │(destination) │
                       └──────────────┘                      └──────────────┘
```

---

## Appendix E: Key Relationships Reference

| From | Relation | To | Business Meaning |
|------|----------|----| -----------------|
| Equipment | asset | Asset | Equipment belongs to a mill |
| Recipe | productDefinition | ProductDefinition | Recipe makes a product |
| Recipe | equipment | Equipment | Recipe runs on equipment |
| Reel | productDefinition | ProductDefinition | Reel is a batch of product |
| Reel | equipment | Equipment | Reel made on equipment |
| Roll | reel | Reel | Roll cut from reel |
| Roll | package | Package | Roll bundled in package |
| Package | sourcePlant | Asset | Package ships from mill |
| Package | destinationPlant | Asset | Package ships to facility |
| QualityResult | reel | Reel | Quality test on reel |
| QualityResult | roll | Roll | Quality test on roll |
| MaterialCostVariance | productDefinition | ProductDefinition | Cost impacts product |
| Event | asset | Asset | Event occurs at asset |
| MfgTimeSeries | asset | Asset | TimeSeries from asset |
| CogniteFile | assets | Asset | File linked to asset |

---

## Appendix F: GitHub Documentation Index

**Reference Documentation:**
- [Data Model Specification](../../../reference/data-model/DATA_MODEL_SPECIFICATION.md)
- [Architecture Decisions & Roadmap](../../../reference/data-model/ARCHITECTURE_DECISIONS_AND_ROADMAP.md)
- [Transformations](../../../reference/data-model/TRANSFORMATIONS.md)
- [Use Cases & Queries](../../../reference/use-cases/USE_CASES_AND_QUERIES.md)
- [Johan ISA-95 Guidance](../../../reference/data-model/JOHAN_ISA95_GUIDANCE_SUMMARY.md)
- [Data Model Walkthrough](../../../reference/data-model/DATA_MODEL_WALKTHROUGH.md)
- [Extractors](../../../reference/extractors/EXTRACTORS.md)
- [CI/CD Overview](../../../reference/cicd/CICD_OVERVIEW.md)

**Internal Working Documents:**
- [Sprint 2 Plan](../../../archive/2026-02-sprint2-completed/SPRINT_2_PLAN.md)
- [Sprint 2 Story Mapping](../../../archive/2026-02-sprint2-completed/SPRINT_2_STORY_MAPPING.md)

---

*Speaker notes for Sylvamo CDF Data Model presentation*
