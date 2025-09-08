# 📝 Where Do Multi‑Stage Build Artifacts Live? (Docker SDK → ASP.NET) 

When you use **multi‑stage Docker builds** (e.g., `sdk:8.0` → `aspnet:8.0`), the “extra stuff” from the **build stage** does **not** leak into your project folder. Here’s exactly where it goes, how caching works, and how to clean it up — with commands you can copy‑paste. ✅

---

## ⚡ TL;DR
- The **first stage** (e.g., `FROM dotnet/sdk:8.0 AS build`) creates **intermediate layers** stored **inside Docker’s local cache**, **not** in your repo.  
- Only files you **`COPY --from=build`** make it into the **final image** (e.g., `aspnet:8.0`).  
- The unused build layers remain in Docker’s cache to **speed up future builds**.  
- Clean them with `docker builder prune` (safe for cache) or `docker system prune -a` (aggressive).  

---

## 🧠 What Actually Happens

```text
+--------------------------+        COPY --from=build        +-----------------------------+
|  Stage A: dotnet/sdk     |  ───────────────────────────▶   | Stage B: dotnet/aspnet      |
|  - restore, build,       |                                 | - only published output     |
|    publish to /app/out   |                                 |   is included to run        |
+--------------------------+                                 +-----------------------------+
           │
           └───► Intermediate layers cached by Docker (for speed)
```

- **Stage A (SDK)**: creates `/src/bin`, `/src/obj`, NuGet cache (`/root/.nuget/packages` inside the container), plus the output `/app/out`.  
- **Stage B (ASP.NET runtime)**: copies **only** `/app/out` (or whatever you specify) from Stage A.  
- **Everything else** from Stage A remains in **Docker’s build cache**, **not** your host repo.

---

## 📦 Where Is the Cache Stored?

- **Linux hosts** (default overlay2):  
  - `/var/lib/docker/overlay2/` + metadata under `/var/lib/docker`  
- **Docker Desktop (macOS/Windows)**:  
  - Stored **inside the Docker VM** (not directly on your filesystem).  

> These files are **managed by Docker**. You generally don’t browse them manually — you query/clean them via Docker CLI.

---

## 🔎 Inspect Space Usage

```bash
# High-level view of space used by images/containers/volumes/build cache
docker system df

# Show build cache details (BuildKit)
docker buildx du

# History of a specific image (layers & sizes)
docker history <image:tag>
```

---

## 🧼 Cleaning Up (from light to heavy)

> ⚠️ **Always review** the output. Some commands delete images/containers you still need.

```bash
# Remove dangling images (untagged)
docker image prune -f

# Remove stopped containers, dangling images, unused networks
docker system prune -f

# Aggressive: also remove unused images (not just dangling) and build cache
docker system prune -a

# Only prune build cache (safe for just cache)
docker builder prune -f

# BuildKit-specific: prune all caches across builders
docker buildx prune -a -f
```

**Tip:** Run `docker system df` before/after to see the effect.

---

## 🚀 Why Keep Those Layers?
- They **speed up future builds** (e.g., no need to re‑restore NuGet packages if `.csproj` didn’t change).  
- Docker reuses layer checksums to skip work.  
- If you don’t want reuse for a given build:  
  ```bash
  docker compose build --no-cache
  # or
  docker build --no-cache -t myimage .
  ```

---

## 📁 What If I Want the NuGet Cache on the Host?

By default, NuGet packages are cached **inside** the build container at `/root/.nuget/packages`.  
You can **persist** or **share** it across builds with a volume:

```bash
# Reuse host NuGet cache to speed up restores
docker build   --build-arg NUGET_PACKAGES=/root/.nuget/packages   -t myimage .
```

Or in a Compose/BuildKit setup, mount a cache volume in the build stage (example pattern):

```dockerfile
# example (BuildKit) — enables a cached mount for NuGet
# syntax=docker/dockerfile:1.6
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Cached mount for NuGet packages across builds
RUN --mount=type=cache,target=/root/.nuget/packages     dotnet nuget locals all --list

COPY DotNetMongoCRUDApp.csproj ./
RUN --mount=type=cache,target=/root/.nuget/packages     dotnet restore DotNetMongoCRUDApp.csproj

COPY . .
RUN --mount=type=cache,target=/root/.nuget/packages     dotnet publish DotNetMongoCRUDApp.csproj -c Release -o /app/out --no-restore
```

> Requires BuildKit (enabled by default in recent Docker). This **persists NuGet cache** across builds without bloating final images.

---

## 🧩 Pro Tips

- **Only copy what you need**: `COPY --from=build /app/out /app` keeps runtime images lean.  
- **Order matters**: copy `*.csproj` and run `restore` **before** copying the whole source — best caching.  
- **Force fresh deps**: use `--pull` on build to refresh base images; use `--no-cache` if needed.  
- **Targets**: build specific stages with `--target`, or debug with `--progress=plain`.  
- **Measure**: `docker system df`, `docker buildx du`, `docker history` to see where space goes.

---

## ✅ In Short
- Stage A artifacts (SDK build) live in **Docker’s build cache**, not in your repo.  
- The final image only contains **what you explicitly copy** from the build stage.  
- Clean cache with `docker builder prune` (safe) or `docker system prune -a` (aggressive).  
- Use cached mounts (BuildKit) if you want to **reuse NuGet** across builds **without** bloating images.

Happy building! 🐳🚀
