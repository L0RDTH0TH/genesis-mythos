# Documentation Directory

This directory contains all project documentation organized by category.

## Directory Structure

```
docs/
├── README.md                          # This file - documentation index
├── api/                               # API Reference Documentation
│   └── API_REFERENCE.md              # Complete API reference for all public classes
├── schemas/                           # Data Schema Documentation
│   └── DATA_SCHEMAS.md               # JSON schema documentation for all data files
├── technical/                         # Technical Implementation Documentation
│   └── CurrentVisualPipelineDocumentation.gd  # Visual rendering pipeline documentation
├── testing/                           # Testing Documentation
│   ├── README.md                     # Testing overview
│   ├── RUNNING_TESTS.md              # How to run tests
│   ├── TEST_COVERAGE_MATRIX.md       # Test coverage matrix
│   ├── CHARACTER_CREATION_COVERAGE.md # Character creation test coverage
│   ├── WORLD_GENERATION_COVERAGE.md  # World generation test coverage
│   ├── FANTASY_STYLE_PRESET_TESTS.md # Fantasy style preset tests
│   ├── CHANGELOG.md                  # Testing changelog
│   └── audiences/                    # Audience-specific test documentation
│       └── RICHTEXTLABEL_SCROLL_FAILURE_AUDIT.md
├── archive/                           # Archived/Deprecated Documentation (63 files)
│   ├── README.md                     # Archive directory guide
│   ├── debug/                        # Debug and diagnostic reports (20+ files)
│   ├── status/                        # Status reports and fix summaries (20+ files)
│   ├── analysis/                      # Analysis and investigation reports (15+ files)
│   ├── audits/                        # Audit reports (5+ files)
│   └── guides/                        # Historical guides and templates (2 files)
└── world_generation.md                # Current world generation system documentation
```

## Documentation Categories

### API Documentation (`api/`)

Complete API reference for all public classes, methods, signals, and properties.

- **API_REFERENCE.md**: Comprehensive API documentation with usage examples

### Data Schemas (`schemas/`)

Documentation for all JSON data file structures and schemas.

- **DATA_SCHEMAS.md**: Complete JSON schema reference with examples

### Technical Documentation (`technical/`)

Low-level technical implementation details and architecture documentation.

- **CurrentVisualPipelineDocumentation.gd**: Complete visual rendering pipeline documentation

### Testing Documentation (`testing/`)

Test coverage, test execution guides, and testing best practices.

- **README.md**: Testing overview and quick start
- **RUNNING_TESTS.md**: Detailed guide on running tests
- **TEST_COVERAGE_MATRIX.md**: Complete test coverage matrix
- **CHARACTER_CREATION_COVERAGE.md**: Character creation test coverage
- **WORLD_GENERATION_COVERAGE.md**: World generation test coverage
- **FANTASY_STYLE_PRESET_TESTS.md**: Fantasy style preset test documentation
- **CHANGELOG.md**: Testing system changelog

### Archive (`archive/`)

Completed audits, historical plans, and deprecated documentation.

**Structure:**
- `debug/` - Debug and diagnostic reports
- `status/` - Status reports and fix summaries
- `analysis/` - Analysis and investigation reports
- `audits/` - Audit reports
- `guides/` - Historical guides and templates

Files in this directory are kept for reference but are no longer actively maintained. See [archive/README.md](./archive/README.md) for details.

### Root Documentation

- **world_generation.md**: Current world generation system documentation (actively maintained)

## Quick Links

- [API Reference](./api/API_REFERENCE.md)
- [Data Schemas](./schemas/DATA_SCHEMAS.md)
- [World Builder Wizard Guide](./WORLD_BUILDER_WIZARD_GUIDE.md) - **NEW**: Complete guide to the wizard-style world builder
- [World Builder API Reference](./WORLD_BUILDER_API_REFERENCE.md) - **NEW**: API documentation for world builder classes
- [World Generation System](./world_generation.md)
- [Testing Documentation](./testing/README.md)
- [Technical Documentation](./technical/CurrentVisualPipelineDocumentation.gd)

## Contributing

When adding new documentation:

1. **API Documentation** → Place in `api/`
2. **Data Schema Documentation** → Place in `schemas/`
3. **Technical Documentation** → Place in `technical/`
4. **Testing Documentation** → Place in `testing/`
5. **Completed Audits/Historical Docs** → Move to `archive/`

## Maintenance

- **Current Documentation**: Keep in appropriate category folders
- **Deprecated Documentation**: Move to `archive/` folder
- **Outdated Plans**: Archive when superseded by new documentation

---

*Last Updated: 2025-01-09*
