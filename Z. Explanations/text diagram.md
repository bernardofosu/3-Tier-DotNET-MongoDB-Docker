
```sh
                ┌────────────────────────────────────────────────────┐
                │ Stage 1: BUILD (sdk:8.0)                           │
docker build →  │  FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build    │
                │  WORKDIR /src                                      │
                │  COPY *.csproj …  → dotnet restore  (NuGet cache)  │
                │  COPY . .        → dotnet publish  → /app/out      │
                └───────────────▲────────────────────────────────────┘
                                │
                                │  (artifacts & layers live in
                                │   Docker’s build cache / layer store,
                                │   e.g. /var/lib/docker/overlay2)
                                │
                                ▼
                ┌────────────────────────────────────────────────────┐
                │ Stage 2: RUNTIME (aspnet:8.0)                      │
                │  FROM mcr.microsoft.com/dotnet/aspnet:8.0          │
                │  WORKDIR /app                                      │
                │  COPY --from=build /app/out .   ← only this copied │
                │  ENTRYPOINT ["dotnet","YourApp.dll"]               │
                └───────────────────▲────────────────────────────────┘
                                    │
                                    │ final image layers only include:
                                    │  • aspnet runtime base
                                    │  • files from /app/out
                                    │
                                    ▼
                         docker run / push / deploy



```