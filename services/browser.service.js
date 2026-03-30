import { chromium } from 'playwright';
import { liveScores, matchIds, matchIdToMessageId } from '../state/store.js';
import { normalizeMessageId } from '../utils/helper.js';

let browser;
let page;

export async function initBrowser() {
    browser = await chromium.launch({
        headless: true,
        channel: 'chrome'
    });

    const context = await browser.newContext({
        userAgent: 'Mozilla/5.0 Chrome/120 Safari/537.36'
    });

    page = await context.newPage();

    await page.addInitScript(() => {
        Object.defineProperty(navigator, 'webdriver', {
            get: () => false
        });
    });

    let lastFastApiTime = null;
    let lastDetailsApiTime = null;

    page.on('response', async (response) => {
        try {
            const now = Date.now();
            const url = response.url();

            if (url.includes('/fastscore/message/base')) {

                if (lastFastApiTime) {
                    //console.log(`⏱ Fast API interval: ${now - lastFastApiTime} ms`);
                }
                lastFastApiTime = now;

                //console.log("fast api");

                const fullMessageId = new URL(url).searchParams.get('messageId');
                const normalized = normalizeMessageId(fullMessageId);
                const matchId = normalized.split('-')[1];

                if (matchIds.includes(matchId)) {
                    const data = await response.json();
                    liveScores[normalized] = data;
                    matchIdToMessageId[matchId] = normalized;
                }

                //console.log('Match detail updated - fast :', matchId);

            } else if (url.includes('/v1/pages/match/details')) {

                if (lastDetailsApiTime) {
                    //console.log(`⏱ Details API interval: ${now - lastDetailsApiTime} ms`);
                }
                lastDetailsApiTime = now;

                const data = await response.json();
                const matchId = data?.match?.objectId;

                if (matchId) {
                    liveScores[matchId] = data;
                    matchIdToMessageId[matchId] = matchId;
                }

                //console.log('Match detail - api :', matchId);
            }

        } catch (err) {
            console.error(err);
        }
    });

    console.log('🚀 Browser ready');
}

export function getPage() {
    return page;
}