# 📝 Difference: `mcr.microsoft.com/dotnet/sdk:8.0` vs `mcr.microsoft.com/dotnet/aspnet:8.0` (and what the final stage runs)

A clear, copy‑pasteable guide to **what each image contains**, **why we use both in multi‑stage builds**, and **what `DotNetMongoCRUDApp.dll` is doing** in the final stage. ✅

---

## ⚡ TL;DR (Quick Matrix)

| Feature | `sdk:8.0` 🛠️ | `aspnet:8.0` 🚀 | `runtime:8.0` 📦 |
|---|---|---|---|
| Contains .NET **runtime** | ✅ | ✅ | ✅ |
| Contains **compilers** & build tools | ✅ `dotnet build/restore/publish`, `csc`, NuGet | ❌ | ❌ |
| **Purpose** | **Build & publish** apps | **Run** ASP.NET Core apps | **Run** non‑web / console services |
| Typical **image size** | **Larger** (build toolchain included) | **Smaller** | **Smallest** of the three |
| Use in Dockerfile | Build stage | Final runtime stage for web | Final runtime stage for console apps |

> In multi‑stage builds: **sdk** compiles → **aspnet** (or **runtime**) runs.

---

## 🛠️ 1) `dotnet/sdk:8.0` — Full SDK (Build Image)

**Includes:**  
- .NET **Runtime**  
- **Compilers** (`csc`, `fsc`, etc.)  
- **Build tools** (`dotnet build`, `dotnet restore`, `dotnet publish`)  
- **NuGet** package manager

**Purpose:** building & publishing your app (CI/CD, local builds).  
**Size:** larger (has full toolchain).

**Example (build stage):**
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish DotNetMongoCRUDApp.csproj -c Release -o /app/out
```

---

## 🚀 2) `dotnet/aspnet:8.0` — ASP.NET Core Runtime (Run Image)

**Includes:**  
- .NET **Runtime**  
- **ASP.NET Core** libraries (Web API, MVC, Razor, Blazor Server)

**Does NOT include:** compilers/SDK tools.

**Purpose:** **running** apps in production (web workoads).  
**Size:** smaller than SDK.

**Example (final stage):**
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/out .
ENTRYPOINT ["dotnet","MyApp.dll"]
```

---

## 📦 3) `dotnet/runtime:8.0` — .NET Runtime (non‑web)

**Includes:** .NET Runtime only (no ASP.NET Core web stack).  
**Purpose:** running console/background services that **don’t** use ASP.NET Core.  
**Size:** often **smaller** than `aspnet` (no web libs).

---

## 🧱 4) Why We Use Both — Multi‑Stage Build Flow

1) **Build** in the **sdk** image → `dotnet publish` produces optimized output (DLLs, configs, static assets) in `/app/out`.  
2) **Run** in the **aspnet** image → copy only the published output → small, secure, fast runtime image.

**Benefits:**  
- Smaller final image → faster pulls/startup.  
- Reduced attack surface (no compilers in prod).  
- Better layer caching (faster CI/CD).

---

## 🔎 5) Breaking Down the Final Stage You Wrote

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
ENV ASPNETCORE_URLS=http://0.0.0.0:5035
COPY --from=build /app/out .
EXPOSE 5035
ENTRYPOINT ["dotnet","DotNetMongoCRUDApp.dll"]
```

- **`FROM mcr.microsoft.com/dotnet/aspnet:8.0`** → choose the **ASP.NET Core runtime** image to run a web app.  
- **`WORKDIR /app`** → set the working directory; subsequent relative paths will resolve here.  
- **`ENV ASPNETCORE_URLS=http://0.0.0.0:5035`** → instruct Kestrel to **bind on all interfaces** inside the container at port **5035** (so Docker can publish it with `-p 5035:5035`).  
- **`COPY --from=build /app/out .`** → copy the **published output** from the **build** stage to the current working directory (`/app`).  
- **`EXPOSE 5035`** → documentation hint declaring the app listens on **5035** (you still need `-p 5035:5035` to publish it).  
- **`ENTRYPOINT ["dotnet","DotNetMongoCRUDApp.dll"]`** → start the app by invoking the .NET runtime with your compiled DLL.

---

## 💡 6) What is `DotNetMongoCRUDApp.dll` & Why Are We Running It?

- It’s the **compiled output** of your project after `dotnet publish`.  
- Contains your app’s **entry point** (`Program.cs` → `Main`), dependency assemblies, and runtime config files in `/app/out`.  
- Running it with:
  ```bash
  dotnet DotNetMongoCRUDApp.dll
  ```
  uses the .NET runtime (provided by the `aspnet:8.0` image) to **launch** your ASP.NET Core app.  
- `ASPNETCORE_URLS` makes **Kestrel** listen on `0.0.0.0:5035` so the container can accept traffic from outside.

> On Linux, the default is a **DLL** launched by `dotnet`. You *could* publish a **self‑contained** executable, but that increases image size. The DLL + runtime image keeps things small and portable.

---

## 🧪 7) Quick Checks

```bash
# Build & run
docker build -t dotnet-mongo:latest .
docker run --rm -p 5035:5035 dotnet-mongo:latest

# Test endpoint
curl -I http://localhost:5035
```

If you see a 200/301/404 header response, your container is serving HTTP at port 5035.

---

## 🧭 8) Common Gotchas & Tips

- **Port mismatch:** ensure your app listens on the **same port** you publish (`ASPNETCORE_URLS` vs `EXPOSE` vs `-p`).  
- **Bind to `0.0.0.0`:** using `localhost` inside containers prevents external traffic; use `0.0.0.0`.  
- **Healthcheck:** add a simple `/health` endpoint; in Compose/K8s define a healthcheck/readiness probe.  
- **Cache restore:** copy `*.csproj` first, run `restore`, then copy the rest (faster incremental builds).  
- **No SDK in prod:** keep runtime images lean; only the **aspnet** or **runtime** base is needed to **run**.

---

## ✅ Summary

- **`sdk:8.0`** → full toolchain for **building** (`restore/build/publish`).  
- **`aspnet:8.0`** → **run** ASP.NET Core apps in production (smaller).  
- **Final stage** runs `dotnet DotNetMongoCRUDApp.dll`, which starts your compiled app; `ASPNETCORE_URLS` binds it on port **5035**.  
- This multi‑stage pattern creates **small, efficient images** perfect for deployment. 🐳🚀
