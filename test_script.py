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