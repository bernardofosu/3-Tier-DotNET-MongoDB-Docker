# 📝 Linux-based vs Windows-based .NET Docker Images

A practical, copy‑pasteable guide comparing **Linux** and **Windows** .NET container images — when to use each, key differences, and ready-made Dockerfile examples. ✅

---

## ⚡ TL;DR
- **Most apps:** use **Linux-based** images — smaller, faster, portable across Linux servers, CI/CD, and cloud.  
- **Use Windows-based** images **only** if you need **Windows-only dependencies** (e.g., COM, GDI, certain native libs) or must run on Windows Server.  
- You **cannot** run Windows containers on a Linux host (and vice versa). On Windows, you must switch Docker to **Windows containers** mode to run them.

---

## 🐧 Linux-based (.NET 8)

```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish -c Release -o /app/out

# Runtime stage (ASP.NET Core)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/out ./
ENV ASPNETCORE_URLS=http://0.0.0.0:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "YourApp.dll"]
```

- **Shell:** `/bin/sh`, `/bin/bash`  
- **Paths:** Linux style (`/app/out`)  
- **Pros:** smaller images (~200–300 MB for SDK; runtime even smaller), faster pulls/startup, runs on Linux servers, Kubernetes, GitHub Actions, GitLab CI, etc.  
- **Cons:** Linux‑only — cannot load Windows-only native components.  
- **Common base tags:**  
  - `mcr.microsoft.com/dotnet/sdk:8.0` (build)  
  - `mcr.microsoft.com/dotnet/aspnet:8.0` (runtime for web)  
  - `mcr.microsoft.com/dotnet/runtime:8.0` (runtime for console/services)  

### ✅ When to choose Linux images
- Target runtime is Linux (most cloud/K8s environments).  
- No Windows‑only native dependencies.  
- You want smaller footprints and faster CI/CD cycles.

---

## 🪟 Windows-based (.NET 8)

```dockerfile
# Build stage (Windows NanoServer)
FROM mcr.microsoft.com/dotnet/sdk:8.0-nanoserver-ltsc2022 AS build
WORKDIR C:\src
COPY . .
RUN dotnet publish -c Release -o C:\app\out

# Runtime stage (ASP.NET Core on NanoServer)
FROM mcr.microsoft.com/dotnet/aspnet:8.0-nanoserver-ltsc2022 AS final
WORKDIR C:\app
COPY --from=build C:\app\out .
# Windows containers typically bind via app settings or profile; EXPOSE is optional
ENTRYPOINT ["dotnet", "YourApp.dll"]
```

- **Shell:** `cmd.exe` or PowerShell (depending on `SHELL` directive)  
- **Paths:** Windows style (`C:\app\out`)  
- **Pros:** required for Windows‑only workloads (COM, certain drivers, legacy Windows APIs).  
- **Cons:** **large images** (often **1–2+ GB**), slower pulls, **requires Windows host** (Windows Server or Windows 11/10 in **Windows containers** mode).  
- **Common base tags:**  
  - `mcr.microsoft.com/dotnet/sdk:8.0-nanoserver-ltsc2022`  
  - `mcr.microsoft.com/dotnet/aspnet:8.0-nanoserver-ltsc2022`  

### ✅ When to choose Windows images
- You depend on Windows‑only native libraries or features.  
- You deploy to Windows Server and must remain Windows‑native.  
- You’re containerizing a legacy .NET (Framework) app (note: .NET Framework uses different base images).

---

## 🧭 Key Differences

| Feature | Linux-based (`dotnet/sdk:8.0`) | Windows-based (`dotnet/sdk:8.0-nanoserver`) |
|---|---|---|
| **Base OS** | Debian/Ubuntu (or similar) | Windows NanoServer / Server Core |
| **Shell** | `bash` / `sh` | `cmd` / `powershell` |
| **Paths** | `/app/out` | `C:\app\out` |
| **Image Size** | ~200–300 MB (SDK); smaller for runtime | 1–2 GB+ (SDK/runtime) |
| **Portability** | Runs on Linux, Windows, macOS (Docker using Linux containers) | **Windows only** (Windows containers mode) |
| **File system** | Case‑sensitive, POSIX perms | Case‑insensitive by default |
| **Line endings** | LF | CRLF (commonly) |
| **Default shell form** | `/bin/sh -c` | `cmd /S /C` (or PowerShell via `SHELL`) |
| **Best for** | Cloud/K8s, CI/CD, microservices | Windows‑specific workloads |

> ℹ️ Windows containers require **Windows hosts**. Docker Desktop can switch between Linux and Windows containers, but you can’t run both modes simultaneously.

---

## 🧱 Real‑world Tips & Gotchas

### 🔧 Executable bits & line endings
- On Linux images, scripts must be **executable**: `RUN chmod +x script.sh` and use **LF** line endings.  
- On Windows images, PowerShell scripts often need `SHELL ["pwsh", "-Command"]` or `["powershell", "-Command"]`.

### 🗂️ Volume mounts & paths
- Linux: `-v $PWD:/app` works with `/app` paths.  
- Windows: use Windows path escaping, e.g. `-v C:\src:C:\app` (or Docker Desktop path translation).

### 🔐 Users & permissions
- Linux images typically run as `root` unless changed (`USER 1000`).  
- Windows images often run as `ContainerUser` by default; adjust ACLs if needed.

### 🌐 Networking
- **EXPOSE** is documentation only; ensure your app binds to `0.0.0.0` on Linux or appropriate address on Windows.  
- Kestrel: set `ASPNETCORE_URLS=http://0.0.0.0:<port>` in Linux containers.

---

## 🏗️ Linux vs Windows – Side‑by‑side Dockerfiles

### 🐧 Linux multi‑stage (SDK → ASP.NET runtime)
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o /app/out

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/out ./
ENV ASPNETCORE_URLS=http://0.0.0.0:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "YourApp.dll"]
```

### 🪟 Windows multi‑stage (SDK → ASP.NET runtime)
```dockerfile
# Use cmd by default; you can switch to PowerShell:
# SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
FROM mcr.microsoft.com/dotnet/sdk:8.0-nanoserver-ltsc2022 AS build
WORKDIR C:\src
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o C:\app\out

FROM mcr.microsoft.com/dotnet/aspnet:8.0-nanoserver-ltsc2022 AS final
WORKDIR C:\app
COPY --from=build C:\app\out .
ENTRYPOINT ["dotnet", "YourApp.dll"]
```

---

## 🔍 Choosing Guide

- ✅ **Choose Linux** if: cloud/Kubernetes target, smallest images, fastest CI/CD, cross‑platform dev teams.  
- ✅ **Choose Windows** if: you rely on Windows‑only APIs, legacy components, or strict Windows Server constraints.  
- 🤝 **Both:** Build **multi‑arch/multi‑OS** images for different environments; publish separate tags (e.g., `:linux-x64`, `:windows-ltsc2022`).

---

## 🧪 Build both variants (advanced)

```bash
# Linux image
docker build -t yourapp:linux -f Dockerfile.linux .

# Windows image (run this on a Windows host in Windows containers mode)
docker build -t yourapp:windows -f Dockerfile.windows .
```

> You can also use `docker buildx` to orchestrate multiple targets, but **Windows containers still require a Windows builder/host**.

---

## ✅ Summary

- **Linux-based** .NET images → **default choice**: smaller, faster, widely portable.  
- **Windows-based** .NET images → **niche/required** when you need Windows-only dependencies.  
- Paths, shells, image sizes, and host requirements **differ significantly** — pick the base that matches your runtime and dependencies.
