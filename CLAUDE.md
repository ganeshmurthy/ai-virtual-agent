# Claude Code Project Instructions

## Git Workflow

### New Files
**IMPORTANT**: Whenever you create a new file using the Write tool, immediately run `git add <file-path>` to stage it. This ensures new files are included in git status and commits.

Example:
```bash
# After creating a new file
git add path/to/new/file.yaml
```

### Commit Messages
Follow conventional commit format:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation
- `refactor:` for code refactoring
- `test:` for test changes
- `chore:` for build/tooling changes

## Development Guidelines

### Image Registries
- Production: `quay.io/rh-ai-quickstart`
- Testing: `quay.io/ganeshmurthy`

### Security
- Always store API keys and sensitive data in Kubernetes Secrets using `secretKeyRef`
- Never use plaintext `value:` for sensitive environment variables
- Follow the existing chart pattern (e.g., `pgSecret`)

### Helm Charts
- Test template rendering with `helm template` before deploying
- Follow existing patterns in the chart for consistency
- Update dependencies with `helm dependency update` when modifying subcharts
