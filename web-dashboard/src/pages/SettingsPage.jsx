import { useState, useEffect } from 'react'
import { useTheme } from '../context/ThemeContext'
import { useLocale } from '../context/LocaleContext'
import { SUPPORTED_LOCALES } from '../i18n/translations'
import './SettingsPage.css'

const DESKTOP_NOTIFY_KEY = 'cc_desktop_notify'

export default function SettingsPage() {
  const { theme, setTheme } = useTheme()
  const { t, locale, setLocale } = useLocale()
  const [desktopNotify, setDesktopNotify] = useState(() => {
    try {
      return localStorage.getItem(DESKTOP_NOTIFY_KEY) === '1'
    } catch {
      return false
    }
  })
  const [notifyDeniedHint, setNotifyDeniedHint] = useState(false)

  useEffect(() => {
    try {
      localStorage.setItem(DESKTOP_NOTIFY_KEY, desktopNotify ? '1' : '0')
    } catch {
      /* ignore */
    }
  }, [desktopNotify])

  const requestNotifyPermission = async () => {
    if (typeof Notification === 'undefined') return false
    if (Notification.permission === 'granted') return true
    if (Notification.permission === 'denied') {
      setNotifyDeniedHint(true)
      return false
    }
    const result = await Notification.requestPermission()
    if (result === 'denied') setNotifyDeniedHint(true)
    return result === 'granted'
  }

  const handleDesktopToggle = async (checked) => {
    setNotifyDeniedHint(false)
    if (checked) {
      const ok = await requestNotifyPermission()
      setDesktopNotify(ok)
    } else {
      setDesktopNotify(false)
    }
  }

  return (
    <div className="settings-page">
      <h1>{t('settings.title')}</h1>

      <section className="settings-section">
        <h2>{t('settings.theme')}</h2>
        <div className="setting-row">
          <label>{t('settings.appearance')}</label>
          <select value={theme} onChange={(e) => setTheme(e.target.value)}>
            <option value="system">{t('settings.appearance.system')}</option>
            <option value="light">{t('settings.appearance.light')}</option>
            <option value="dark">{t('settings.appearance.dark')}</option>
          </select>
        </div>
      </section>

      <section className="settings-section">
        <h2>{t('settings.language')}</h2>
        <div className="setting-row">
          <label htmlFor="cc-locale">{t('settings.language')}</label>
          <select
            id="cc-locale"
            value={locale}
            onChange={(e) => setLocale(e.target.value)}
          >
            {SUPPORTED_LOCALES.map((code) => (
              <option key={code} value={code}>
                {t(`settings.lang.${code}`)}
              </option>
            ))}
          </select>
        </div>
      </section>

      <section className="settings-section">
        <h2>{t('settings.notifications')}</h2>
        <p className="settings-hint">{t('settings.desktopNotifyHint')}</p>
        <div className="setting-row">
          <label>{t('settings.desktopNotify')}</label>
          <label className="toggle">
            <input
              type="checkbox"
              checked={desktopNotify}
              onChange={(e) => handleDesktopToggle(e.target.checked)}
            />
            <span className="toggle-slider" />
          </label>
        </div>
        {typeof Notification !== 'undefined' &&
          Notification.permission === 'default' &&
          !desktopNotify && (
            <button type="button" className="settings-link-btn" onClick={() => handleDesktopToggle(true)}>
              {t('settings.desktopNotifyEnable')}
            </button>
          )}
        {notifyDeniedHint && (
          <p className="settings-warning">{t('settings.desktopNotifyDenied')}</p>
        )}
      </section>

      <section className="settings-section">
        <h2>{t('settings.security')}</h2>
        <div className="setting-row">
          <span>{t('settings.resetPassword')}</span>
          <a
            href="#"
            onClick={(e) => {
              e.preventDefault()
              window.alert(t('settings.resetAlert'))
            }}
          >
            {t('settings.resetViaEmail')}
          </a>
        </div>
      </section>
    </div>
  )
}
