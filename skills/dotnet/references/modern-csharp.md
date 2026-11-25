# Modern C# & .NET Reference (Verified by TFM)

Always gate language/API usage on the **specific project's** `<TargetFramework>` and `<LangVersion>` from `detect-env.sh`. Never use `net11.0` / C# 15 features in a `net10.0` project.

## Universal Modern Baseline (.NET 8–11 / C# 12–15)
- **Types & immutability:** `sealed` classes by default; `record` / `readonly record struct` for DTOs & value objects; `required` + `init` for valid construction; file-scoped namespaces; collection expressions (`[]`, `[..items]`).
- **Guards:** `ArgumentNullException.ThrowIfNull`, `ArgumentException.ThrowIfNullOrWhiteSpace`, `ArgumentOutOfRangeException.ThrowIfNegative` / `ThrowIfNegativeOrZero` (prefer over manual `if` + `throw`).
- **Primary constructors:** Use for DI classes **when the repo uses them**; assign or validate if mutable/null-checked (remember captured params are mutable unless stored in `readonly` fields).
- **Time & Concurrency:** Inject `TimeProvider` (never `DateTime.Now`/`UtcNow` in testable domain logic). On .NET 9+ (C# 13+), prefer `System.Threading.Lock` over `object` for synchronous locks; never `lock` across `await` (use `SemaphoreSlim`).
- **Logging:** `ILogger<T>` message templates (`"Order {OrderId} cancelled"`) or `[LoggerMessage]` source-generated methods on hot paths—never `$""` interpolation.
- **HTTP & Resilience:** Use `IHttpClientFactory` (typed/named clients) + `Microsoft.Extensions.Http.Resilience` (`AddStandardResilienceHandler()` / `AddResilienceHandler()`, built on Polly v8). Do **not** use `new HttpClient()` per call or legacy `Microsoft.Extensions.Http.Polly` (Polly v7) for new code.
- **Performance collections:** `FrozenDictionary`/`FrozenSet` for read-heavy static lookups; `SearchValues<T>` and `ReadOnlySpan<T>` on hot parsing paths; `ConfigureAwait(false)` in reusable class libraries (unnecessary in ASP.NET Core app code).

## .NET 10 LTS / C# 14 (supported to Nov 2028)
- **C# 14 language:**
  - **`field` keyword:** Custom getter/setter logic directly on auto-properties without manual backing fields (`init => field = value.Trim();`).
  - **Extension members:** `extension(T receiver)` blocks supporting extension properties, operators, and static extension members (not only methods).
  - **Null-conditional assignment:** `order?.DiscountCode = code;` (short-circuits RHS when null).
  - **Unbound generics in `nameof`:** `nameof(List<>)`.
  - **First-class `Span<T>` / `ReadOnlySpan<T>` conversions:** Implicit array-to-span conversions and improved generic/extension inference.
  - **Simple lambda parameter modifiers:** `(text, out value) => int.TryParse(text, out value)` without explicit types.
  - **Partial constructors & partial events** (great for source generators); **user-defined compound assignment operators** (`+=`, `-=`).
- **ASP.NET Core 10:** Built-in Minimal API validation (`builder.Services.AddValidation()`), OpenAPI 3.1 (`Microsoft.AspNetCore.OpenApi`), native Server-Sent Events (`TypedResults.ServerSentEvents`), Blazor WASM asset preloading & `NotFoundPage`, Identity passkeys.
- **EF Core 10:** First-class LINQ `LeftJoin` / `RightJoin`, native SQL Server `json` mapping + `ExecuteUpdateAsync` with non-expression lambdas, named query filters, optional complex types, vector search (`SqlVector<float>` / `EF.Functions.VectorDistance`).

## .NET 11 STS / C# 15 (check TFM = `net11.0` first!)
- **C# 15 language:**
  - **Union types:** `public union Pet(Cat, Dog, Bird);` with compiler-enforced exhaustive `switch` expressions (ideal for typed domain outcomes without third-party union libraries).
  - **Closed hierarchies:** Compiler-tracked restricted inheritance hierarchies.
  - **Collection expression arguments**, **extension indexers**, **labeled `break`/`continue`**.
- **.NET 11 runtime & libraries:** Runtime Async (runtime-native async execution, cleaner stack traces), `System.Text.Json` union serialization, native Zstandard compression (`System.IO.Compression`), expanded `Process` run-and-capture helpers, NativeAOT `dotnet` CLI host, `Microsoft.AspNetCore.Components.AI` for Blazor AI UIs, OpenAPI 3.2.
- If a specific C# 15 / .NET 11 overload or signature is uncertain, compile it or verify via `learn.microsoft.com` before relying on it.
