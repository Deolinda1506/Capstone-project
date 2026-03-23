import { useState, useEffect } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { API_BASE, useAuth } from '../context/AuthContext'
import { useLocale } from '../context/LocaleContext'
import './LoginPage.css'

export default function ResetPasswordPage() {
  const { t } = useLocale()
  const { logout } = useAuth()
  const [searchParams] = useSearchParams()
  const tokenFromUrl = searchParams.get('token') || ''

  const [token, setToken] = useState(tokenFromUrl)
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [done, setDone] = useState(false)

  useEffect(() => {
    if (tokenFromUrl) setToken(tokenFromUrl)
  }, [tokenFromUrl])

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    if (password.length < 6) {
      setError(t('reset.errorShort'))
      return
    }
    if (password !== confirm) {
      setError(t('reset.errorMismatch'))
      return
    }
    if (!token.trim()) {
      setError(t('reset.errorNoToken'))
      return
    }
    setLoading(true)
    try {
      const res = await fetch(`${API_BASE}/auth/reset-password`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token: token.trim(), new_password: password }),
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
      logout()
      setDone(true)
    } catch (err) {
      const msg = err?.message || ''
      const isNetwork =
        err?.name === 'TypeError' ||
        msg === 'Failed to fetch' ||
        msg.includes('NetworkError')
      setError(
        isNetwork
          ? t('reset.errorNetwork')
          : msg || t('reset.error'),
      )
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <h1>{t('reset.title')}</h1>
        <p className="login-subtitle">{t('reset.subtitle')}</p>
        {done ? (
          <>
            <p className="forgot-success">{t('reset.success')}</p>
            <Link to="/login" className="btn btn-primary btn-block">
              {t('reset.goLogin')}
            </Link>
          </>
        ) : (
          <form onSubmit={handleSubmit} className="login-form">
            {!tokenFromUrl && (
              <label>
                {t('reset.tokenLabel')}
                <input
                  type="text"
                  value={token}
                  onChange={(e) => setToken(e.target.value)}
                  placeholder={t('reset.tokenPlaceholder')}
                  autoComplete="off"
                />
              </label>
            )}
            <label>
              {t('reset.newPassword')}
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder={t('login.passwordPlaceholder')}
                required
                minLength={6}
                autoComplete="new-password"
              />
            </label>
            <label>
              {t('reset.confirmPassword')}
              <input
                type="password"
                value={confirm}
                onChange={(e) => setConfirm(e.target.value)}
                placeholder={t('login.passwordPlaceholder')}
                required
                minLength={6}
                autoComplete="new-password"
              />
            </label>
            {error && <div className="login-error">{error}</div>}
            <button type="submit" className="btn btn-primary btn-block" disabled={loading}>
              {loading ? t('reset.submitting') : t('reset.submit')}
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
