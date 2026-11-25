# .NET UI/UX & Accessibility Reference (WCAG 2.2 AA)

Load when building or changing Blazor, Razor Pages/MVC, .NET MAUI, or SPA + .NET API UIs. Match the repo's existing design system/component library before introducing new primitives.

## Accessibility Baseline (WCAG 2.2 AA — Default Target)
- **Semantics first:** Native `<button>`, `<a href>`, `<label for>`, `<fieldset>`/`<legend>`, heading hierarchy (`h1` → `h2` → `h3` without skipping). Add ARIA only when native semantics don't exist.
- **Keyboard & focus:** Every interactive control reachable via Tab with visible focus indicator (`:focus-visible`, never `outline: none` without a replacement); modal dialogs trap focus and restore it on close; Escape dismisses overlays.
- **Forms & errors:** Associate every input with `<label>` (never placeholder-only); wire error messages with `aria-describedby` + `aria-invalid="true"`; announce async status/errors with `role="status"` (`aria-live="polite"`) or `role="alert"`.
- **Contrast & targets:** ≥4.5:1 normal text (≥3:1 large text & UI borders/icons); interactive touch/click targets ≥24×24 CSS px (prefer ≥44×44 on mobile/MAUI); never convey state by color alone (pair with text/icon).
- **Motion & zoom:** Respect `prefers-reduced-motion`; support 200% zoom / 320px reflow without horizontal scrolling.

## Blazor (Server / WebAssembly / Interactive Auto)
- **Render modes:** Set `@rendermode` at component **usage** or route level, not hard-coded inside reusable components. Keep static pages SSR unless interactivity is needed.
- **Data & DbContext:** In Blazor Server / Interactive Server, **never** inject scoped `DbContext` into long-lived components—inject `IDbContextFactory<T>` and create a short-lived context per operation.
- **Lifecycle & leaks:** Always pass `CancellationToken` (cancel in `Dispose`/`DisposeAsync` via `IDisposable`/`IAsyncDisposable`); unsubscribe event handlers and dispose `PeriodicTimer` / JS `IJSObjectReference` in `DisposeAsync`.
- **Prerendering:** Avoid duplicate fetches during SSR + interactive hydration (`PersistentComponentState` or `[PersistentState]` on .NET 10+).
- **Forms & performance:** Use `<EditForm>` + `<DataAnnotationsValidator>` + `<ValidationMessage>` (supply `FormName` for static SSR). Always add `@key` in `@foreach` loops; use `<Virtualize>` for large lists; keep `StateHasChanged()` rare.
- **Components:** Split large components into `X.razor`, `X.razor.cs`, `X.razor.css` (CSS isolation); keep business logic in injected services, not `.razor` markup.

## Razor Pages & ASP.NET Core MVC
- **Thin PageModels / Controllers:** Bind dedicated ViewModel / InputModel DTOs (never EF entities) with `[BindProperty]`; validate `ModelState.IsValid` server-side even when client validation is enabled.
- **PRG & CSRF:** Use Post-Redirect-Get (`RedirectToPage` / `RedirectToAction`) after mutations to prevent duplicate submits; keep anti-forgery tokens active (`asp-page` / `[ValidateAntiForgeryToken]`).
- **Tag Helpers & ViewComponents:** Prefer built-in Tag Helpers (`asp-for`, `asp-validation-for`) so `id`/`for`/`aria-*` stay synced automatically; extract reusable fragments into ViewComponents or Partial Views.

## .NET MAUI
- **MVVM & bindings:** Use `CommunityToolkit.Mvvm` (`[ObservableProperty]`, `[RelayCommand]`) when in the repo; always set `x:DataType` for **compiled bindings** (faster + compile-time safe).
- **Lists & responsiveness:** Use `CollectionView` (never legacy `ListView`); keep layouts flat (`Grid` over nested `StackLayout`); keep main/UI thread free (`await` off UI thread, marshal UI updates via `MainThread`).
- **Accessibility:** Set `SemanticProperties.Description`, `SemanticProperties.Hint`, and `SemanticProperties.HeadingLevel` on non-text/custom controls; ensure ≥44×44 dp touch targets; test light/dark (`AppThemeBinding`) and font scaling.

## JS SPA + .NET API
- **Clean contract boundary:** Generate typed API clients/schemas from .NET OpenAPI (`Microsoft.AspNetCore.OpenApi`) instead of hand-duplicating DTOs.
- **ProblemDetails everywhere:** Return RFC 9457 `ProblemDetails` (`errors` dictionary for 400/422) so the frontend maps field-level validation errors consistently.
- **Auth:** Prefer BFF (Backend-for-Frontend) with `HttpOnly`, `Secure`, `SameSite` cookies over storing JWTs in `localStorage`.
