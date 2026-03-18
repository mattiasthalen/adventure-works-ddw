# Adventure Works Ddw

Data transformation project created with [Daana CLI](https://github.com/daana-code/daana-cli).

## Project Structure

```
Adventure Works Ddw/
├── model.yaml          # Your data model (entities, attributes, relationships)
├── workflow.yaml       # Workflow orchestration (links model + mappings + connections)
├── connections.yaml    # Database connection profiles (your data warehouse)
├── docker-compose.yml  # Local databases for development
├── mappings/          # Entity mapping files (generated)
└── README.md          # This file
```

## Understanding Daana's Architecture

Daana uses a **two-database architecture**:

1. **Customer Database** (port 5432) - Your data warehouse
   - Contains your **data lake** (raw source tables)
   - Contains **transformed business entities** in the `daana_dw` schema
   - Configured in `connections.yaml`
   - This is where Daana reads from your sources and writes clean data

2. **Internal Database** (port 5434) - Daana's control database
   - Stores metadata (models, mappings, workflows)
   - Orchestrates transformations
   - Configured in `~/.daana/config.yaml` (created automatically)
   - You typically don't interact with this database directly

## Quick Start

### 0. Start Local Databases

Start both databases using Docker:

```bash
docker-compose up -d
```

Verify databases are running:
```bash
docker-compose ps
```

### 1. Edit Your Model

Open `model.yaml` and define your business entities:
- Add entities that represent your business concepts (CUSTOMER, ORDER, PRODUCT, etc.)
- Define attributes for each entity
- Specify relationships between entities

**Validate your model:**
```bash
daana-cli check model model.yaml
```

### 2. Generate and Configure Mappings

Generate mapping templates to connect your source data to the model:

```bash
# Generate mappings for all entities
daana-cli generate mapping \
  --model model.yaml \
  --all-entities \
  --dir mappings/

# Or generate for a specific entity
daana-cli generate mapping \
  --model model.yaml \
  --entity CUSTOMER \
  --out mappings/customer-mapping.yaml
```

Edit the generated templates in `mappings/` to specify your source tables and column mappings.

### 3. Validate Your Configuration

Check everything before deployment:

```bash
daana-cli check workflow workflow.yaml
```

### 4. Deploy Everything

Deploy your complete data transformation:

```bash
daana-cli deploy workflow.yaml
```

This single command:
- ✅ Validates your model and mappings
- ✅ Installs the framework to both databases
- ✅ Prepares your workflow for execution

### 5. Execute Workflows

Run your data transformation workflows:

```bash
daana-cli execute workflow.yaml --batch-start "2025-01-01" --batch-end "2025-01-31"
```

## Next Steps

- **Learn More**: Visit [docs.daana.dev](https://docs.daana.dev)
- **Get Help**: Run `daana-cli --help` or `daana-cli [command] --help`
- **Join Community**: [GitHub Discussions](https://github.com/daana-code/daana-cli/discussions)

## Workflow Commands

```bash
# Validate configurations
daana-cli check model model.yaml
daana-cli check workflow workflow.yaml
daana-cli check connections

# Deploy and execute
daana-cli deploy workflow.yaml
daana-cli execute workflow.yaml

# Generate additional mappings
daana-cli generate mapping --model model.yaml --entity NEW_ENTITY --out mappings/new-mapping.yaml
```

## Tips

1. **Start Simple**: Begin with one entity and one mapping, then expand
2. **Validate Often**: Run `check` commands after every change
3. **Version Control**: Commit your YAML files to git
4. **Environment Variables**: Never commit passwords - use env vars in production
5. **Incremental Development**: Test each entity's mapping before adding more

---

Generated with Daana CLI v0.5.17
