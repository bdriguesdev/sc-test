const scrapers = require('./scrapers');

// Get the SCRAPERS environment variable (defaults to '*' to run all)
const scrapersToRun = process.env.SCRAPERS || '*';

console.log(`Environment variable SCRAPERS: ${scrapersToRun}`);

// Parse the scrapers to run
let selectedScrapers = [];

if (scrapersToRun === '*') {
  // Run all scrapers
  selectedScrapers = Object.keys(scrapers);
  console.log('Running all scrapers...\n');
} else {
  // Parse comma-separated list of scrapers
  selectedScrapers = scrapersToRun.split(',').map(s => s.trim());
  console.log(`Running selected scrapers: ${selectedScrapers.join(', ')}\n`);
}

// Execute selected scrapers sequentially
(async () => {
  for (const scraperName of selectedScrapers) {
    if (scrapers[scraperName]) {
      try {
        await scrapers[scraperName]();
      } catch (error) {
        console.error(`Failed to run ${scraperName}: ${error.message}`);
        process.exit(1);
      }
    } else {
      console.error(`Error: Scraper '${scraperName}' not found`);
      process.exit(1);
    }
  }
  
  console.log('All scrapers completed successfully!');
})();

// # Build the image
// docker build -t sc-test:latest .

// # Run with all scrapers (default)
// docker run sc-test:latest

// # Run with specific scrapers
// docker run -e SCRAPERS=xe,wise sc-test:latest

// # Or use Docker Compose
// docker-compose up

// 652897434952