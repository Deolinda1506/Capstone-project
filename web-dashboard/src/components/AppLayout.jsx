import { Link, NavLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { useSearch } from '../context/SearchContext'
import { useState, useEffect } from 'react'
import { getHighRisk } from '../api/client'
import './AppLayout.css'

const SIDEBAR_LINKS = [
  { label: 'DASHBOARD', items: [
    { to: '/dashboard', label: 'Overview' },
    { to: '/team', label: 'Team' },
  ]},
  { label: 'SYSTEM', items: [
    { to: '/settings', label: 'Settings' },
    { label: 'Logout', action: 'logout' },
  ]},
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
  const navigate = useNavigate()
  const [notificationsOpen, setNotificationsOpen] = useState(false)
  const [highRisk, setHighRisk] = useState([])

  useEffect(() => {
    getHighRisk(20).then(setHighRisk).catch(() => setHighRisk([]))
  }, [])

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const count = highRisk.length

  return (
    <div className="app-layout">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <span className="sidebar-logo">CarotidCheck</span>
        </div>
        <nav className="sidebar-nav">
          {SIDEBAR_LINKS.map((group) => (
            <div key={group.label} className="sidebar-group">
              <div className="sidebar-group-label">{group.label}</div>
              {group.items.map((item) =>
                item.action === 'logout' ? (
                  <button key="logout" className="sidebar-link" onClick={handleLogout}>
                    {item.label}
                  </button>
                ) : (
                  <SidebarLink key={item.to} to={item.to} label={item.label} />
                )
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
              placeholder="Search by patient name, ID, or scan ID..."
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
                aria-label="Notifications"
              >
                <span className="icon-bell">🔔</span>
                {count > 0 && <span className="badge">{count}</span>}
              </button>
              {notificationsOpen && (
                <div className="notifications-dropdown">
                  <div className="dropdown-header">High-risk referrals</div>
                  {highRisk.length === 0 ? (
                    <div className="dropdown-empty">No high-risk referrals</div>
                  ) : (
                    <ul className="dropdown-list">
                      {highRisk.slice(0, 10).map((r) => (
                        <li key={r.scan_id}>
                          <Link
                            to={`/referral/${r.scan_id}`}
                            onClick={() => setNotificationsOpen(false)}
                          >
                            {r.patient_name || r.patient_identifier} — {r.risk_level} — {r.imt_mm} mm
                          </Link>
                        </li>
                      ))}
                    </ul>
                  )}
                </div>
              )}
            </div>
            <span className="user-name">{user?.display_name || user?.email || 'User'}</span>
          </div>
        </header>

        <div className="page-content">{children}</div>
      </main>
    </div>
  )
}
