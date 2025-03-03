import asyncio
import nodriver as uc
import os
import time

async def main():
    print("Starting browser...")
    
    # Configure browser with appropriate settings for Docker environment
    browser = await uc.start(
        headless=True,
        additional_browser_args=[
            "--no-sandbox",
            "--disable-dev-shm-usage",
            "--disable-gpu"
        ]
    )
    
    try:
        print("Browser started successfully!")
        
        # Navigate to a website
        print("Navigating to example.com...")
        page = await browser.get("https://www.example.com")
        
        # Get page title
        title = await page.title
        print(f"Page title: {title}")
        
        # Take a screenshot
        screenshot_path = os.path.join(os.path.expanduser("~/Downloads"), f"example_{int(time.time())}.png")
        await page.save_screenshot(screenshot_path)
        print(f"Screenshot saved to: {screenshot_path}")
        
        # Get page content
        content = await page.get_content()
        print(f"Page content length: {len(content)} characters")
        
        # Find elements
        elements = await page.select_all("a")
        print(f"Found {len(elements)} links on the page")
        
        # Print the href of each link
        for i, elem in enumerate(elements[:5]):  # Limit to first 5 links
            href = await elem.get_attribute("href")
            text = await elem.text
            print(f"Link {i+1}: {text} -> {href}")
        
        # Open a new tab
        print("\nOpening a new tab to github.com...")
        github_page = await browser.get("https://github.com/ultrafunkamsterdam/nodriver", new_tab=True)
        
        # Get page title
        github_title = await github_page.title
        print(f"GitHub page title: {github_title}")
        
        # Take a screenshot of the GitHub page
        github_screenshot_path = os.path.join(os.path.expanduser("~/Downloads"), f"github_{int(time.time())}.png")
        await github_page.save_screenshot(github_screenshot_path)
        print(f"GitHub screenshot saved to: {github_screenshot_path}")
        
        # Switch back to the first tab
        await page.bring_to_front()
        print("Switched back to first tab")
        
        # Demonstrate some more advanced features
        print("\nDemonstrating some advanced features...")
        
        # Scroll down
        await page.scroll_down(200)
        print("Scrolled down 200 pixels")
        
        # Wait a moment for any events to process
        await asyncio.sleep(1)
        
        # Reload the page
        await page.reload()
        print("Reloaded the page")
        
    finally:
        # Always close the browser
        print("\nClosing browser...")
        await browser.close()
        print("Browser closed")

if __name__ == "__main__":
    print("Starting nodriver Docker example...")
    uc.loop().run_until_complete(main())
    print("Example completed successfully!") 