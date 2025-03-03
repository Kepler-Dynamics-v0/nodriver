# Docker Setup for Nodriver

This Docker setup allows you to run the Nodriver package in a containerized environment on your Ubuntu VPS.

## Prerequisites

- Docker installed on your VPS
- Docker Compose installed on your VPS

## Getting Started

1. Clone the repository to your VPS:
   ```bash
   git clone https://github.com/ultrafunkamsterdam/nodriver.git
   cd nodriver
   ```

2. Build and start the Docker container:
   ```bash
   docker-compose up --build -d
   ```

3. Create a data directory for downloads and screenshots:
   ```bash
   mkdir -p data
   ```

## Running Examples

To run one of the example scripts:

1. Edit the `docker-compose.yml` file and uncomment the command line, specifying which example to run:
   ```yaml
   command: python example/demo.py
   ```

2. Restart the container:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Running Your Own Scripts

1. Create a directory for your scripts:
   ```bash
   mkdir -p my_scripts
   ```

2. Add your script to the directory, for example `my_scripts/my_script.py`:
   ```python
   import asyncio
   import nodriver as uc

   async def main():
       browser = await uc.start()
       page = await browser.get('https://www.example.com')
       await page.save_screenshot()
       await browser.close()

   if __name__ == '__main__':
       uc.loop().run_until_complete(main())
   ```

3. Mount your scripts directory in the `docker-compose.yml` file:
   ```yaml
   volumes:
     - ./example:/app/example
     - ./my_scripts:/app/my_scripts
     - ./data:/home/nodriver/Downloads
   ```

4. Update the command in `docker-compose.yml`:
   ```yaml
   command: python my_scripts/my_script.py
   ```

5. Restart the container:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Headless Mode

By default, Chrome runs in headless mode in the container. If you need to modify Chrome options, you can do so in your script:

```python
import asyncio
import nodriver as uc

async def main():
    # Add additional Chrome arguments if needed
    browser = await uc.start(
        headless=True,  # Already the default in container
        additional_browser_args=["--disable-gpu", "--no-sandbox"]
    )
    # Rest of your code...

if __name__ == '__main__':
    uc.loop().run_until_complete(main())
```

## Troubleshooting

### Chrome crashes or doesn't start

If Chrome crashes or doesn't start, you might need to add additional flags:

```python
browser = await uc.start(
    headless=True,
    additional_browser_args=[
        "--no-sandbox",
        "--disable-dev-shm-usage",
        "--disable-gpu"
    ]
)
```

### Viewing logs

To view the logs from the container:

```bash
docker-compose logs -f
```

### Interactive Shell

To get an interactive shell in the container:

```bash
docker-compose exec nodriver bash
``` 