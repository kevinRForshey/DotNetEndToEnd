# SOLID & Pragmatic .NET Design Patterns

Apply SOLID to reduce coupling and change risk—never to add ceremony. Match architectural depth to domain complexity.

## SOLID in Idiomatic C#/.NET

| Principle | Do | Avoid |
|---|---|---|
| **S — Single Responsibility** | Separate domain rules (pure, unit-testable) from transport/I/O (thin endpoints, handlers, Razor code-behind). Split types along distinct reasons to change. | God `*Service`/`*Manager` classes mixing validation, pricing, SQL, HTTP, and email; fat controllers. |
| **O — Open/Closed** | Add variants via polymorphism + DI: `IEnumerable<IRule>`, keyed services (`AddKeyedScoped` / `[FromKeyedServices]`), Strategy, Decorator, Middleware, `IEndpointFilter`. | Growing `switch`/`if-else` ladders on provider/type strings modified every sprint. |
| **L — Liskov Substitution** | Honor base contracts, nullability, `CancellationToken`, and invariants. Default classes to `sealed`; prefer composition over inheritance. | Overrides throwing `NotSupportedException`, weakening postconditions, or hiding members with `new`. |
| **I — Interface Segregation** | Keep interfaces cohesive (role-based, ~1–4 members: `ITaxRateProvider`, `IClock`). Split read vs write seams when callers differ. | Fat 15-method `IOrderService`; pointless 1:1 `IFoo` interfaces for value objects, records, or internal helpers ("interfaceitis"). |
| **D — Dependency Inversion** | Inject abstractions at volatile/I/O boundaries (`TimeProvider`, typed `HttpClient`, storage, payment gateways). Use constructor injection. | Service Locator (`IServiceProvider.GetRequiredService` inside business logic); referencing EF/HTTP SDKs from domain core. |

## GoF Patterns → Built-in .NET Idioms

Name the pattern, the force it resolves, and the simpler alternative rejected. If no force exists, use plain classes/functions.

| Pattern | Use when... | Idiomatic .NET form | Don't use when... |
|---|---|---|---|
| **Strategy** | Runtime-selectable or extensible algorithms (payment providers, discount rules, parsers) | Keyed DI (`AddKeyedScoped<IPaymentProvider>("stripe")`) or `IEnumerable<IRule>` with `CanHandle` | Only 1–2 stable branches unlikely to grow |
| **Decorator** | Cross-cutting concerns around an interface (caching, metrics, retry, audit) | DI factory / Scrutor decoration; `DelegatingHandler` for `HttpClient`; ASP.NET Core middleware | A single private helper method suffices |
| **Factory** | Creation needs runtime args, pooled/scoped lifetimes, or provider dispatch | `Func<T>`, `IHttpClientFactory`, `IDbContextFactory<T>`, `IKeyedServiceProvider` | Plain `new` or standard DI constructor works |
| **Chain of Responsibility** | Ordered request/message pipeline with short-circuiting | ASP.NET Core middleware, `IEndpointFilter`, `DelegatingHandler` | Linear 2-step method call |
| **Observer / Pub-Sub** | Decoupled notifications or async producer/consumer | `Channel<T>` (bounded, in-process async), `IAsyncEnumerable<T>`, domain events | Direct synchronous call to one known consumer |
| **Options / Builder** | Typed, validated configuration or complex fluent setup | `IOptions<T>` / `IOptionsSnapshot<T>` / `IOptionsMonitor<T>` + `ValidateDataAnnotations().ValidateOnStart()` | 2 constructor parameters |

## DI Lifetimes & Architecture Guardrails
- **Lifetime hierarchy:** Singleton → never inject Scoped or Transient-holding-Scoped (captive dependency). Enable `ValidateScopes` & `ValidateOnBuild` in dev/tests. To use a scoped service inside a `BackgroundService`/Singleton, inject `IServiceScopeFactory` and create a scope per unit of work.
- **EF Core & Repository:** `DbContext` is already a Unit of Work + Repository. Don't wrap it in a generic `IRepository<T>` that leaks `IQueryable` or blocks projections/batching; use focused query/persistence abstractions or vertical-slice handlers directly on `DbContext`.
- **Exceptions vs Result types:** Throw exceptions for programmer bugs (`ArgumentNullException`), violated invariants, or infrastructure faults. Return typed results (`TypedResults`, discriminated union on C# 15, or lightweight `record` result) for expected domain/validation outcomes at boundaries.
- **Pragmatic layering:** A small API fits Vertical Slices (feature folder with endpoint + handler + validator + DTOs) far better than 5 empty Clean Architecture projects. Extract a separate Domain/Application project only when multiple hosts or rich invariants justify it.
