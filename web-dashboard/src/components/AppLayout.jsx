import { Link, NavLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { useSearch } from '../context/SearchContext'
import { useLocale } from '../context/LocaleContext'
import { usePendingReferrals } from '../context/PendingReferralsContext'
import { useState } from 'react'
import './AppLayout.css'

const SIDEBAR_LINKS = [
  {
    labelKey: 'nav.group.dashboard',
    items: [
      { to: '/dashboard', labelKey: 'nav.overview' },
      { to: '/team', labelKey: 'nav.team' },
    ],
  },
  {
    labelKey: 'nav.group.system',
    items: [
      { to: '/settings', labelKey: 'nav.settings' },
      { labelKey: 'nav.logout', action: 'logout' },
    ],
  },
]

function SidebarLink({ to, label }) {
  return (
    <NavLink to={to} className={({ isActive }) => `sidebar-link ${isActive ? 'active' : ''}`}>
      {label}
    </NavLink>
  )
}

export default function AppLayout({ children }) {
  const { user, logout } = useAuth()
  const { searchQuery, setSearchQuery } = useSearch()
  const { t } = useLocale()
  const { highRisk, alertBanner, setAlertBanner } = usePendingReferrals()
  const navigate = useNavigate()
  const [notificationsOpen, setNotificationsOpen] = useState(false)

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const count = highRisk.length

  return (
    <div className="app-layout">
      {alertBanner && (
        <div className="referral-alert-banner" role="status">
          <span className="referral-alert-text">
            {t('layout.newReferralBanner', { count: alertBanner.count })}
          </span>
          <Link to="/dashboard" className="referral-alert-link" onClick={() => setAlertBanner(null)}>
            {t('layout.viewDashboard')}
          </Link>
          <button type="button" className="referral-alert-dismiss" onClick={() => setAlertBanner(null)}>
            {t('layout.dismiss')}
          </button>
        </div>
      )}

      <div className="app-layout-body">
        <aside className="sidebar">
          <div className="sidebar-brand">
            <span className="sidebar-logo">CarotidCheck</span>
          </div>
          <nav className="sidebar-nav">
            {SIDEBAR_LINKS.map((group) => (
              <div key={group.labelKey} className="sidebar-group">
                <div className="sidebar-group-label">{t(group.labelKey)}</div>
                {group.items.map((item) =>
                  item.action === 'logout' ? (
                    <button key="logout" className="sidebar-link" onClick={handleLogout}>
                      {t(item.labelKey)}
                    </button>
                  ) : (
                    <SidebarLink key={item.to} to={item.to} label={t(item.labelKey)} />
                  ),
                )}
              </div>
            ))}
          </nav>
        </aside>

        <main className="main-content">
          <header className="topbar">
            <div className="topbar-search">
              <input
                type="search"
                placeholder={t('layout.searchPlaceholder')}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="search-input"
              />
            </div>
            <div className="topbar-actions">
              <div className="notifications-wrap">
                <button
                  className="icon-btn notifications-btn"
                  onClick={() => setNotificationsOpen((v) => !v)}
                  aria-label={t('layout.notificationsAria')}
                >
                  <span className="icon-bell">🔔</span>
                  {count > 0 && <span className="badge">{count}</span>}
                </button>
                {notificationsOpen && (
                  <div className="notifications-dropdown">
                    <div className="dropdown-header">{t('layout.notificationsTitle')}</div>
                    {highRisk.length === 0 ? (
                      <div className="dropdown-empty">{t('layout.notificationsEmpty')}</div>
                    ) : (
                      <ul className="dropdown-list">
                        {highRisk.slice(0, 10).map((r) => (
                          <li key={r.scan_id}>
                            <Link
                              to={`/referral/${r.scan_id}`}
                              onClick={() => setNotificationsOpen(false)}
                            >
                              {r.patient_name || r.patient_identifier} — {r.risk_level} —{' '}
                              {r.imt_mm != null ? `${r.imt_mm} mm` : '—'}
                            </Link>
                          </li>
                        ))}
                      </ul>
                    )}
                  </div>
                )}
              </div>
              <span className="user-name">{user?.display_name || user?.email || t('layout.userFallback')}</span>
            </div>
          </header>

          <div className="page-content">{children}</div>
        </main>
      </div>
    </div>
  )
}
