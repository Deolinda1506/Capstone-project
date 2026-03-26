import { test, expect } from '@playwright/test'

const identifier = process.env.E2E_IDENTIFIER?.trim()
const password = process.env.E2E_PASSWORD ?? ''

test.describe('login → dashboard (real API)', () => {
  test.beforeEach(() => {
    test.skip(
      !identifier || !password,
      'Set E2E_IDENTIFIER and E2E_PASSWORD (real staff user on the target API).',
    )
  })

  test('staff can log in and see overview', async ({ page }) => {
    await page.goto('/login')
    await page.getByTestId('login-identifier').fill(identifier)
    await page.getByTestId('login-password').fill(password)
    await page.getByTestId('login-submit').click()

    await expect(page).toHaveURL(/\/dashboard$/, { timeout: 30_000 })
    await expect(page.getByTestId('dashboard-root')).toBeVisible()
    await expect(page.getByRole('heading', { level: 1 })).toBeVisible({ timeout: 60_000 })
  })
})
