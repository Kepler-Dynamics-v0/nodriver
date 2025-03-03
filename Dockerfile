FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Install Chrome dependencies and Chrome
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

# Create a non-root user to run Chrome (Chrome won't run as root without --no-sandbox)
RUN groupadd -r nodriver && useradd -r -g nodriver -G audio,video nodriver \
    && mkdir -p /home/nodriver/Downloads \
    && chown -R nodriver:nodriver /home/nodriver \
    && chown -R nodriver:nodriver /app

# Switch to non-root user
USER nodriver

# Set Chrome executable path for nodriver
ENV CHROME_EXECUTABLE_PATH=/usr/bin/google-chrome-stable
# Set default Chrome arguments for headless operation in VM environment
ENV NODRIVER_CHROME_ARGS="--headless=new --no-sandbox --disable-dev-shm-usage --disable-gpu --disable-software-rasterizer --disable-extensions --disable-setuid-sandbox --no-first-run --no-zygote --single-process --disable-breakpad"

# Create a simple test script
RUN echo 'import asyncio\nimport nodriver as uc\n\nasync def main():\n    browser = await uc.start(headless=True, additional_browser_args=["--no-sandbox", "--disable-dev-shm-usage", "--disable-gpu", "--disable-software-rasterizer", "--disable-extensions", "--disable-setuid-sandbox", "--no-first-run", "--no-zygote", "--single-process", "--disable-breakpad"])\n    page = await browser.get("https://www.example.com")\n    print("Page title:", await page.title)\n    await browser.close()\n\nif __name__ == "__main__":\n    uc.loop().run_until_complete(main())' > /app/test_script.py

# Command to run when container starts
# This can be overridden when running the container
CMD ["python", "/app/test_script.py"] 