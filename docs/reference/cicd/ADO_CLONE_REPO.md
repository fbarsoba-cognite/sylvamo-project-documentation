# Programmatically Clone ADO Repository

## Quick Start

```bash
# Clone to default location (./ado-repo-clone)
uv run python scripts/05-utilities/ado_clone_repo.py

# Clone to specific directory
uv run python scripts/05-utilities/ado_clone_repo.py --target-dir /path/to/clone

# Clone specific branch
uv run python scripts/05-utilities/ado_clone_repo.py --branch main
```

## How It Works

The script (`scripts/05-utilities/ado_clone_repo.py`) programmatically clones the ADO repository by:

1. **Credential Discovery**: Uses the same pattern as `ado_inspect.py`:
   - Checks `ADO_PAT` or `AZURE_DEVOPS_EXT_PAT` from `.env`
   - Falls back to Git credential helper (`git credential fill`)
   - Falls back to macOS Keychain (`security find-internet-password`)

2. **Build Clone URL**: Constructs authenticated git URL:
   ```
   https://{PAT}@dev.azure.com/{org}/{project}/_git/{repo}
   ```

3. **Execute Git Clone**: Runs `git clone` command with the authenticated URL

## Authentication Methods

The script supports multiple authentication methods (in order of preference):

1. **Environment Variable**: `ADO_PAT` or `AZURE_DEVOPS_EXT_PAT` in `.env`
2. **Git Credential Helper**: Credentials stored via `git credential fill`
3. **macOS Keychain**: PAT stored in macOS Keychain for `dev.azure.com`

## Example Usage

### Basic Clone

```bash
cd /path/to/sylvamo
uv run python scripts/05-utilities/ado_clone_repo.py
```

This clones to: `./ado-repo-clone/Industrial-Data-Landscape-IDL`

### Clone to Specific Location

```bash
uv run python scripts/05-utilities/ado_clone_repo.py \
  --target-dir ~/workspace/ado-repo
```

### Clone and Copy Pipeline Files

```bash
# 1. Clone repository
uv run python scripts/05-utilities/ado_clone_repo.py \
  --target-dir ~/workspace/ado-repo

# 2. Copy pipeline files
cp -r .devops ~/workspace/ado-repo/Industrial-Data-Landscape-IDL/

# 3. Commit and push
cd ~/workspace/ado-repo/Industrial-Data-Landscape-IDL
git add .devops/
git commit -m "Add CI/CD pipeline files for CDF Toolkit deployment"
git push origin main
```

## Script Options

```
--target-dir PATH    Target directory to clone into
                     (default: ./ado-repo-clone in workspace root)

--branch BRANCH      Branch to checkout
                     (default: default branch from repo)

--org ORG            ADO organization
                     (default: SylvamoCorp)

--project PROJECT    ADO project name
                     (default: Industrial-Data-Landscape-IDL)

--repo REPO          Repository name
                     (default: Industrial-Data-Landscape-IDL)
```

## Troubleshooting

### Error: "Could not find ADO PAT"

**Solution**: Set `ADO_PAT` in `.env` file:
```bash
echo "ADO_PAT=your_pat_here" >> .env
```

Or ensure Git has credentials stored:
```bash
git credential fill <<EOF
protocol=https
host=dev.azure.com
EOF
```

### Error: "Repository not found" or "Permission denied"

**Solution**: 
1. Verify PAT has "Code (Read)" permission
2. Verify organization/project/repo names are correct
3. Check PAT hasn't expired

### Error: "Target directory exists"

**Solution**: 
- Specify a different `--target-dir`
- Or answer 'y' when prompted to remove existing directory

## Security Notes

- PAT is embedded in the clone URL but is masked in output
- Clone URL format: `https://{PAT}@dev.azure.com/...`
- Git stores credentials in `.git/config` - be careful with repository sharing
- Consider using Git credential helper for better security

## Next Steps After Cloning

1. Copy pipeline files from workspace to cloned repo
2. Commit and push pipeline files
3. Create pipelines in ADO UI pointing to the YAML files
4. Configure variable groups and environments

See `ADO_PIPELINE_SETUP.md` for complete setup instructions.
