import { useState } from 'react'
import { useTheme } from '../context/ThemeContext'
import './SettingsPage.css'

export default function SettingsPage() {
  const { theme, setTheme } = useTheme()
  const [notifications, setNotifications] = useState(true)

  return (
    <div className="settings-page">
      <h1>Settings</h1>

      <section className="settings-section">
        <h2>Theme</h2>
        <div className="setting-row">
          <label>Appearance</label>
          <select value={theme} onChange={(e) => setTheme(e.target.value)}>
            <option value="system">System</option>
            <option value="light">Light</option>
            <option value="dark">Dark</option>
          </select>
        </div>
      </section>

      <section className="settings-section">
        <h2>Notifications</h2>
        <div className="setting-row">
          <label>Email notifications for high-risk referrals</label>
          <label className="toggle">
            <input
              type="checkbox"
              checked={notifications}
              onChange={(e) => setNotifications(e.target.checked)}
            />
            <span className="toggle-slider" />
          </label>
        </div>
      </section>

      <section className="settings-section">
        <h2>Security</h2>
        <div className="setting-row">
          <span>Change password</span>
          <a
            href="#"
            onClick={(e) => {
              e.preventDefault()
              window.alert('Use Forgot Password on the login page to reset your password.')
            }}
          >
            Reset via email
          </a>
        </div>
      </section>
    </div>
  )
}
