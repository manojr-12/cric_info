import app from './app.js';
import { initBrowser } from './services/browser.service.js';
import { startPolling } from './services/polling.service.js';

const PORT = 3000;

(async () => {
  await initBrowser();
  startPolling();

  app.listen(PORT, () => {
    console.log(`🌍 http://localhost:${PORT}`);
  });
})();