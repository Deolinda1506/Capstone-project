import { MemoryRouter } from 'react-router-dom'
import { render } from '@testing-library/react'
import { LocaleProvider } from '../context/LocaleContext'
import { ROUTER_FUTURE } from '../routerFutureFlags'

export function renderWithLocale(ui, { route = '/' } = {}) {
  return render(
    <MemoryRouter initialEntries={[route]} future={ROUTER_FUTURE}>
      <LocaleProvider>{ui}</LocaleProvider>
    </MemoryRouter>,
  )
}
