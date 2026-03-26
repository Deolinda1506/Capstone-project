import { defineConfig, devices } from '@playwright/test'

const previewPort = Number(process.env.E2E_PREVIEW_PORT || 4173)
const baseURL = process.env.PLAYWRIGHT_BASE_URL || `http://127.0.0.1:${previewPort}`

/** Baked into `vite build` for preview. Empty omits the var so AuthContext uses the prod default when `DEV` is false. */
const viteApiUrl =
  (process.env.E2E_API_URL || process.env.VITE_API_URL || '').trim() || undefined

export default defineConfig({
  testDir: './e2e',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: 'list',
  use: {
    baseURL,
    trace: 'on-first-retry',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: {
    command: `npm run build && npm run preview -- --host 127.0.0.1 --strictPort --port ${previewPort}`,
    url: baseURL,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
    env: {
      ...process.env,
      ...(viteApiUrl ? { VITE_API_URL: viteApiUrl } : {}),
    },
  },
})
