# ProM 6.15 - Docker Container

Docker container with **[ProM 6.15](https://promtools.org/prom-6-15/)**, accessible through your web browser via noVNC.

<img width="479" height="288.75" alt="image" src="https://github.com/user-attachments/assets/aee4f93f-9690-43d5-a94a-b40da44fc21d" />


## Prerequisites

- **Docker Desktop** installed and running
  - Windows: https://docs.docker.com/desktop/install/windows-install/
  - macOS: https://docs.docker.com/desktop/install/mac-install/
  - Linux: https://docs.docker.com/desktop/install/linux/

Verify Docker is working by opening a terminal and running:

```
docker --version
```

## Quick Start

### 1. Get the image

**Option A — Pull from registry (recommended):**

```
docker pull ghcr.io/aarkue/prom615:latest
```

**Option B — Load from file:**

Download `prom615.tar.gz` from the [GitHub Releases](../../releases) page, then run:

```
docker load -i prom615.tar.gz
```

### 2. Start the container

Run this from the folder where you want your files to be stored (a `shared` subfolder will be created automatically):

If you used **Option A** (registry):
```
docker run -d --name prom615 -p 6080:6080 --platform linux/amd64 --restart unless-stopped -v ./shared:/home/user/shared ghcr.io/aarkue/prom615:latest
```

If you used **Option B** (file):
```
docker run -d --name prom615 -p 6080:6080 --platform linux/amd64 --restart unless-stopped -v ./shared:/home/user/shared prom615:latest
```

### 3. Open the desktop

Open your web browser and go to [http://localhost:6080/vnc.html](http://localhost:6080/vnc.html):

```
http://localhost:6080/vnc.html
```

Click **Connect**. ProM 6.15 will start automatically. If you need to relaunch it or open a terminal, **right-click** on the desktop for a menu.

### 4. Stop and restart

```
docker stop prom615
docker start prom615
```

To remove the container entirely:

```
docker rm -f prom615
```

> **Alternative:** If you have a `docker-compose.yaml` file, you can use `docker compose up` / `docker compose down` instead of the commands above.

## Sharing files

A `shared` folder is automatically created next to your `docker-compose.yaml`. Anything you place in this folder is visible inside the container at `/home/user/shared`, and vice versa.

Use this to move datasets, models, and results between your computer and the container tools.

## Copy & Paste

Ctrl+C / Ctrl+V work normally between applications *inside* the container.

To copy/paste text between **your computer and the container**, use the noVNC clipboard panel:

1. Click the small arrow tab on the left edge of the browser window to open the **noVNC sidebar**.
2. Open the **Clipboard** panel. This is a text box that acts as a bridge between your computer and the container.
3. **Pasting into the container:** Paste your text into the clipboard panel text box (using your normal system paste). Then switch to the container and press **Ctrl+V**.
4. **Copying from the container:** Copy text with **Ctrl+C** inside the container. The text will appear in the clipboard panel text box. Select it there and copy it to your system.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `docker compose` not recognized | Update Docker Desktop, or try `docker-compose` (with hyphen) |
| Port 6080 already in use | Change the port in `docker-compose.yaml`, e.g., `"7080:6080"`, then open `http://localhost:7080/vnc.html` |
| Container starts but browser shows nothing | Wait a few seconds for the VNC server to initialize, then refresh |
| noVNC shows a black screen | Right-click on the desktop. The window manager may just have an empty desktop. Launch an app from the menu |
| Files in `shared/` not visible in the container | Restart the container with `docker compose down` then `docker compose up` |
| Permission denied writing to `shared/` inside the container | This can happen on Linux. Run `sudo chown -R $USER shared/` on the host to fix it |

---

## Maintenance

This section is for instructors/maintainers who need to rebuild or update the image.

### Project structure

```
prom-docker/
  Dockerfile                       # Image definition
  .dockerignore                    # Excludes shared/, etc. from builds
  docker-compose.yaml              # Runtime config (for distribution)
  docker-compose.build.yaml        # Build config (for maintainers)
  start.sh                         # Container startup script
  prom-6.15-all-platforms.tar.gz   # ProM archive
  ProM.png                         # Desktop icon for ProM
```

### Building the image

```
docker compose -f docker-compose.build.yaml build
```

This uses `docker-compose.build.yaml` which includes both `build: .` and `image: prom615:latest`, so the built image is automatically tagged correctly.

### Testing locally

```
docker compose -f docker-compose.build.yaml up
```

### Exporting for distribution

ProM downloads additional files on first launch (e.g., ProM plugins). To save students from this initial setup, export a *container* that has already been through first launch, rather than the clean image.

1. Build and start the container:
   ```
   docker compose -f docker-compose.build.yaml up
   ```
2. Open `http://localhost:6080/vnc.html`, launch ProM, and let it finish the initial setup.
3. In a separate terminal, commit the running container as the distribution image:
   ```
   docker ps
   docker commit <container_id> prom615:latest
   ```
4. Stop the container (`Ctrl+C` or `docker compose down`), then export:
   ```
   docker save prom615:latest -o prom615.tar
   ```

Optionally compress (saves significant space):
- **Linux/macOS:** `gzip prom615.tar`
- **Windows (PowerShell):** use 7-Zip or distribute the `.tar` as-is

### Publishing the image

**Container registry (GHCR):**
```
docker tag prom615:latest ghcr.io/aarkue/prom615:X.Y.Z
docker tag prom615:latest ghcr.io/aarkue/prom615:latest
docker push ghcr.io/aarkue/prom615:X.Y.Z
docker push ghcr.io/aarkue/prom615:latest
```

Replace `X.Y.Z` with the version number matching the GitHub Release (e.g., `0.2.0`).

**GitHub Release:** Create a release with the same version tag and upload the `prom615.tar.gz` file as a release asset.

### What to distribute to students

Point students to the GitHub repo README. They can either pull from the registry or download the `.tar.gz` from the Releases page.

### Technical notes

- **Clipboard** sync between noVNC and the container uses `autocutsel`, which bridges X11's PRIMARY (select-to-copy) and CLIPBOARD (Ctrl+C) selections.
- The image is built for **x86_64 (amd64)**. On Apple Silicon Macs, Docker Desktop will use Rosetta emulation automatically. The `platform: linux/amd64` setting in the compose files (and `--platform linux/amd64` in the `docker run` command) ensures this works correctly.
