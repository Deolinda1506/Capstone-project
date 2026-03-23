import { useState } from 'react'
import { Link } from 'react-router-dom'
import { API_BASE } from '../context/AuthContext'
import { useLocale } from '../context/LocaleContext'
import './LoginPage.css'

export default function ForgotPasswordPage() {
  const { t } = useLocale()
  const [email, setEmail] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [done, setDone] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const res = await fetch(`${API_BASE}/auth/forgot-password`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: email.trim().toLowerCase() }),
      })
      const text = await res.text()
      let data = {}
      if (text) {
        try {
          data = JSON.parse(text)
        } catch {
          data = {}
        }
      }
      if (!res.ok) {
        throw new Error(
          typeof data.detail === 'string' ? data.detail : `Request failed (${res.status})`,
        )
      }
      setDone(true)
    } catch (err) {
      const msg = err?.message || ''
      const isNetwork =
        err?.name === 'TypeError' ||
        msg === 'Failed to fetch' ||
        msg.includes('NetworkError')
      setError(
        isNetwork
          ? t('forgot.errorNetwork')
          : msg || t('forgot.error'),
      )
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <h1>{t('forgot.title')}</h1>
        <p className="login-subtitle">{t('forgot.subtitle')}</p>
        {done ? (
          <>
            <p className="forgot-success">{t('forgot.success')}</p>
            <Link to="/login" className="btn btn-primary btn-block">
              {t('forgot.backToLogin')}
            </Link>
          </>
        ) : (
          <form onSubmit={handleSubmit} className="login-form">
            <label>
              {t('forgot.email')}
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder={t('forgot.emailPlaceholder')}
                required
                autoComplete="email"
              />
            </label>
            <p className="forgot-hint">{t('forgot.hint')}</p>
            {error && <div className="login-error">{error}</div>}
            <button type="submit" className="btn btn-primary btn-block" disabled={loading}>
              {loading ? t('forgot.sending') : t('forgot.submit')}
            </button>
          </form>
        )}
        <p className="login-footer">
          <Link to="/login">{t('forgot.backToLogin')}</Link>
        </p>
      </div>
    </div>
  )
}
