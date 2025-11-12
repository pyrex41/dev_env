# Contributing Guide

### Adding a New Service

1. **Add service to `docker-compose.yml`:**
```yaml
new-service:
  image: your-image:tag
  container_name: wander_new_service
  environment:
    CONFIG: ${CONFIG}
  ports:
    - "${NEW_PORT:-8080}:8080"
  depends_on:
    postgres:
      condition: service_healthy
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
    interval: 5s
    timeout: 3s
    retries: 5
  networks:
    - wander_network
```

2. **Add health check to `Makefile`:**
```makefile
NEW_STATUS=$$(docker inspect --format='{{.State.Health.Status}}' wander_new_service 2>/dev/null || echo "not running");
if [ "$$NEW_STATUS" = "healthy" ]; then echo "$(GREEN)✓ New Service:$(NC) healthy"; else echo "$(RED)✗ New Service:$(NC) $$NEW_STATUS"; fi;
```

3. **Update README services table** (this file)

4. **Test:**
```bash
make dev
make health
```

### Adding a Database Migration

```bash
# 1. Create migration
cd api
pnpm run migrate:create your_migration_name

# 2. Edit migration file
# Location: api/src/migrations/<timestamp>_your_migration_name.ts

# Example:
export const up = async (pgm) => {
  pgm.createTable('users', {
    id: 'id',
    name: { type: 'varchar(100)', notNull: true },
    email: { type: 'varchar(255)', notNull: true, unique: true },
    created_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') }
  });
};

export const down = async (pgm) => {
  pgm.dropTable('users');
};

# 3. Run migration
make migrate

# 4. Test rollback
make migrate-rollback
make migrate
```

### Code Style

**TypeScript:**
- Use strict mode
- No `any` types
- Explicit return types on functions
- Interface over type when possible

**React:**
- Functional components with hooks
- Named exports for components
- Props interfaces defined inline
- Use TypeScript for prop types

**Commands:**
- Add to `Makefile` with description comment
- Follow existing naming patterns
- Include in `make help` output

---

