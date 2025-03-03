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
RUN echo 'import asyncio\nimport nodriver as uc\nimport logging\n\n# Set up logging\nlogging.basicConfig(level=logging.DEBUG)\n\nasync def main():\n    config = uc.Config(\n        headless=False,  # We\'re using Xvfb instead\n        sandbox=False,\n        browser_args=[\n            "--no-sandbox",\n            "--disable-dev-shm-usage",\n            "--disable-gpu",\n            "--disable-software-rasterizer",\n            "--disable-extensions",\n            "--disable-setuid-sandbox",\n            "--no-first-run",\n            "--no-zygote",\n            "--single-process",\n            "--disable-breakpad"\n        ]\n    )\n    try:\n        print("Starting browser...")\n        browser = await uc.start(config=config)\n        print("Browser started, getting page...")\n        page = await browser.get("https://www.example.com")\n        print("Page loaded, getting title...")\n        title = await page.title\n        print("Page title:", title)\n        print("Closing browser...")\n        await browser.close()\n    except Exception as e:\n        print(f"Error: {e}")\n        import traceback\n        print(traceback.format_exc())\n\nif __name__ == "__main__":\n    uc.loop().run_until_complete(main())' > /app/test_script.py

# Create a wrapper script to start Xvfb and run the test
RUN echo '#!/bin/bash\nXvfb :99 -screen 0 1280x1024x24 &\nexport DISPLAY=:99\npython /app/test_script.py' > /app/run.sh && \
    chmod +x /app/run.sh

# Command to run when container starts
CMD ["/app/run.sh"] 