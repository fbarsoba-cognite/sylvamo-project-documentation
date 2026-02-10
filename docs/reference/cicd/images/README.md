# CI/CD Pipeline Images

This folder is for screenshots and diagrams of the CI/CD pipelines.

## Suggested Screenshots to Add

Capture these from Azure DevOps to enrich the documentation:

| File | What to capture | Where to reference |
|------|------------------|-------------------|
| `pipelines-list.png` | Pipelines list (PR Validation, Deploy to Dev & Staging, Promote to Production) | CICD_COMPLETE_SETUP_GUIDE.md, CICD_HANDS_ON_LEARNINGS.md |
| `pr-validation-run.png` | PR Validation pipeline run with Dev + Staging stages | CICD_HANDS_ON_SPEAKER_NOTES.md, CICD_HANDS_ON_LEARNINGS.md |
| `deploy-pipeline-stages.png` | Deploy pipeline showing Dev and Staging stages | CICD_COMPLETE_SETUP_GUIDE.md |
| `promote-to-prod-pipeline.png` | Promote to Production pipeline with approval gate | CICD_HANDS_ON_LEARNINGS.md |
| `variable-groups.png` | Variable groups (dev, staging, prod credentials) | CICD_COMPLETE_SETUP_GUIDE.md |
| `branch-policy.png` | Branch policy on main with PR Validation required | CICD_COMPLETE_SETUP_GUIDE.md |

## How to Add Images

1. Capture the screenshot (PNG or JPG)
2. Save it in this folder with the suggested filename
3. Reference in Markdown: `![Description](images/filename.png)`

## Diagram Note

The Mermaid diagrams in the main docs render as flowcharts on GitHub and don't require image files. Use this folder for actual ADO UI screenshots.
