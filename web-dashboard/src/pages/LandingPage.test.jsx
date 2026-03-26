import { describe, it, expect } from 'vitest'
import { screen } from '@testing-library/react'
import LandingPage from './LandingPage'
import { renderWithLocale } from '../test/test-utils'

describe('LandingPage', () => {
  it('renders brand and primary navigation', () => {
    renderWithLocale(<LandingPage />)

    expect(screen.getByText('CarotidCheck')).toBeInTheDocument()
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent(
      /carotid ultrasound screening/i,
    )
    const loginLinks = screen.getAllByRole('link', { name: /log in/i })
    expect(loginLinks.length).toBeGreaterThanOrEqual(1)
    const registerLinks = screen.getAllByRole('link', {
      name: /register organization/i,
    })
    expect(registerLinks.length).toBeGreaterThanOrEqual(1)
  })
})
