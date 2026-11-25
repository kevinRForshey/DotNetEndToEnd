# ASP.NET Core API & EF Core Data Best Practices

Load when writing HTTP endpoints, middleware, HTTP clients, or EF Core entities/queries. (For EF CLI migration commands, see `dotnet-token-efficient/references/ef-core.md`.)

## ASP.NET Core APIs
- **Thin endpoints:** Endpoints parse/validate input, call a domain service/handler, and map to HTTP results. Keep business rules out of controllers/route lambdas.
- **Minimal APIs vs Controllers:** Match the repo. In Minimal APIs, group routes (`MapGroup`), return `TypedResults` (`Results<Ok<Dto>, NotFound, Conflict<ProblemDetails>>`) for compile-time OpenAPI metadata and direct unit testability.
- **Validation & Errors:**
  - Enable RFC 9457 `ProblemDetails` (`AddProblemDetails()`, `UseExceptionHandler()`) + `IExceptionHandler` to map domain/unhandled failures without leaking stack traces or internal details.
  - On .NET 10+, use native Minimal API validation (`AddValidation()`) or match existing FluentValidation/DataAnnotations conventions.
  - Use accurate status codes: `201 Created` (with `Location`), `204 No Content`, `400`/`422` validation, `401` unauthenticated vs `403` unauthorized, `404` missing, `409 Conflict` state transitions/concurrency.
- **Security & AuthZ:**
  - Make authorization explicit on every route/group (`RequireAuthorization(policy)` / `[Authorize]`; `AllowAnonymous` only intentionally).
  - Prevent IDOR: derive caller identity/tenant from `ClaimsPrincipal`, never from request body/query params; scope queries by owner/tenant.
  - Never bind EF entities directly to request bodies (mass assignment)—always use dedicated request/response DTOs.
- **Reliability & Ops:**
  - Pass `CancellationToken` from endpoint parameter all the way to DB/HTTP calls.
  - Use `IHttpClientFactory` typed clients + `AddStandardResilienceHandler()` (`Microsoft.Extensions.Http.Resilience`) for outbound HTTP; configure timeouts and base addresses via validated `IOptions<T>`.
  - Avoid `Task.Run` inside request handlers (wastes thread-pool threads); use `Channel<T>` + `BackgroundService` for fire-and-forget work.

## EF Core Modeling & Queries
- **Read queries:** Always add `.AsNoTracking()` (or `.AsNoTrackingWithIdentityResolution()` when joining shared graph nodes) on read-only queries.
- **Projections:** `.Select(x => new Dto(...))` directly in LINQ so SQL fetches only needed columns—don't materialize full entities just to map them in memory.
- **Async & Cancellation:** Pass `CancellationToken` to every `ToListAsync`, `FirstOrDefaultAsync`, `SingleOrDefaultAsync`, `AnyAsync`, `CountAsync`, `SaveChangesAsync`. Never call sync `.ToList()`/`.First()` in async paths.
- **N+1 & Cartesian explosion:** Never query inside loops. Avoid lazy loading proxies. When `.Include()` spans multiple collection navigations, add `.AsSplitQuery()` (or project explicitly) to prevent Cartesian blow-up.
- **Bulk mutations:** Use `ExecuteUpdateAsync` / `ExecuteDeleteAsync` for set-based updates/deletes (note: they hit the DB immediately and bypass the change tracker).
- **Schema configuration:** Put entity config in per-entity `IEntityTypeConfiguration<T>` classes (`ApplyConfigurationsFromAssembly`), not a 500-line `OnModelCreating`. Always specify:
  - `HasMaxLength(...)` on strings,
  - `HasPrecision(18, 2)` (or store currency-appropriate precision) on `decimal` columns,
  - indexes for frequent filter/FK/unique lookups,
  - optimistic concurrency tokens (`IsRowVersion()` / `IsConcurrencyToken()`) on contended aggregates.
- **SQL injection safety:** Use `FromSql($"...")` (`FormattableString`, auto-parameterized). Never pass interpolated strings to `FromSqlRaw` or `ExecuteSqlRawAsync`.
- **DbContext lifetime:** Keep `DbContext` Scoped (one per request/unit of work)—never Singleton, never shared concurrently across `Task.WhenAll`. For Blazor Server or background workers, inject `IDbContextFactory<T>` and create a short-lived context per operation.
