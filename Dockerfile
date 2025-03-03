FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Install Chrome dependencies, Chrome, and Xvfb
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    xvfb \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create and set working directory
WORKDIR /app

# Copy project files
COPY . /app/

# Install the package
RUN pip install --no-cache-dir -e .

# Create a non-root user to run Chrome
RUN groupadd -r -g 1000 nodriver && \
    useradd -r -u 1000 -g nodriver -G audio,video nodriver && \
    mkdir -p /home/nodriver/Downloads && \
    chown -R nodriver:nodriver /home/nodriver && \
    chown -R nodriver:nodriver /app && \
    chmod -R 755 /app

# Switch to non-root user
USER nodriver

# Set Chrome executable path for nodriver
ENV CHROME_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# Create a simple test script
RUN cat > /app/test_script.py << 'EOL'
import asyncio
import nodriver as uc
import logging

# Set up logging
logging.basicConfig(level=logging.DEBUG)

async def main():
    config = uc.Config(
        headless=False,  # We're using Xvfb instead
        sandbox=False,
        browser_args=[
            "--no-sandbox",
            "--disable-dev-shm-usage",
            "--disable-gpu",
            "--disable-software-rasterizer",
            "--disable-extensions",
            "--disable-setuid-sandbox",
            "--no-first-run",
            "--no-zygote",
            "--single-process",
            "--disable-breakpad"
        ]
    )
    try:
        print("Starting browser...")
        browser = await uc.start(config=config)
        print("Browser started, getting page...")
        page = await browser.get("https://www.example.com")
        print("Page loaded, getting title...")
        title = await page.title
        print("Page title:", title)
        print("Closing browser...")
        await browser.close()
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        print(traceback.format_exc())

if __name__ == "__main__":
    uc.loop().run_until_complete(main())
EOL

# Create a wrapper script to start Xvfb and run the test
RUN cat > /app/run.sh << 'EOL'
#!/bin/bash
Xvfb :99 -screen 0 1280x1024x24 &
export DISPLAY=:99
python /app/test_script.py
EOL
RUN chmod +x /app/run.sh

# Command to run when container starts
CMD ["/app/run.sh"] 