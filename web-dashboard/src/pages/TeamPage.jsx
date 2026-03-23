import { useState, useEffect, useCallback } from 'react'
import { getTeam, inviteUser } from '../api/client'
import { useLocale } from '../context/LocaleContext'
import { useAuth } from '../context/AuthContext'
import './TeamPage.css'

export default function TeamPage() {
  const { t } = useLocale()
  const { user } = useAuth()
  const isAdmin = (user?.role || '').toLowerCase() === 'admin'

  const [team, setTeam] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const [inviteEmail, setInviteEmail] = useState('')
  const [invitePassword, setInvitePassword] = useState('')
  const [inviteDisplayName, setInviteDisplayName] = useState('')
  const [inviteStaffId, setInviteStaffId] = useState('')
  const [inviteRole, setInviteRole] = useState('clinician')
  const [inviteSubmitting, setInviteSubmitting] = useState(false)
  const [inviteError, setInviteError] = useState('')
  const [inviteSuccess, setInviteSuccess] = useState('')

  const loadTeam = useCallback(() => {
    if (!isAdmin) return Promise.resolve()
    return getTeam()
      .then(setTeam)
      .catch((err) => {
        setError(err.message || 'Failed to load team')
        setTeam([])
      })
  }, [isAdmin])

  useEffect(() => {
    if (!isAdmin) {
      setLoading(false)
      return undefined
    }
    setLoading(true)
    setError('')
    loadTeam().finally(() => setLoading(false))
  }, [isAdmin, loadTeam])

  const handleInvite = async (e) => {
    e.preventDefault()
    setInviteError('')
    setInviteSuccess('')
    if (!inviteEmail.trim() || !invitePassword) {
      setInviteError(t('team.inviteValidation'))
      return
    }
    if (invitePassword.length < 6) {
      setInviteError(t('team.invitePasswordShort'))
      return
    }
    setInviteSubmitting(true)
    try {
      await inviteUser({
        email: inviteEmail.trim(),
        password: invitePassword,
        display_name: inviteDisplayName.trim() || undefined,
        staff_id: inviteStaffId.trim() || undefined,
        role: inviteRole,
      })
      setInviteSuccess(t('team.inviteSuccess'))
      setInviteEmail('')
      setInvitePassword('')
      setInviteDisplayName('')
      setInviteStaffId('')
      setInviteRole('clinician')
      await loadTeam()
    } catch (err) {
      setInviteError(err.message || t('team.inviteError'))
    } finally {
      setInviteSubmitting(false)
    }
  }

  if (!isAdmin) {
    return (
      <div className="team-page">
        <h1>{t('team.title')}</h1>
        <div className="team-only-admin">{t('team.onlyAdmin')}</div>
      </div>
    )
  }

  if (loading) {
    return (
      <div className="team-page">
        <div className="team-loading">{t('team.loading')}</div>
      </div>
    )
  }
  if (error) {
    return (
      <div className="team-page">
        <div className="team-error">{error}</div>
      </div>
    )
  }

  return (
    <div className="team-page">
      <h1>{t('team.title')}</h1>
      <p className="team-subtitle">{t('team.subtitle')}</p>

      <section className="team-invite-card">
        <h2>{t('team.inviteTitle')}</h2>
        <p className="team-invite-hint">{t('team.inviteHint')}</p>
        <form className="team-invite-form" onSubmit={handleInvite}>
          <div className="team-form-row">
            <label htmlFor="invite-role">{t('team.inviteRole')}</label>
            <select
              id="invite-role"
              value={inviteRole}
              onChange={(e) => setInviteRole(e.target.value)}
              disabled={inviteSubmitting}
            >
              <option value="clinician">{t('team.roleClinician')}</option>
              <option value="chw">{t('team.roleChw')}</option>
            </select>
          </div>
          <div className="team-form-row">
            <label htmlFor="invite-email">{t('team.inviteEmail')}</label>
            <input
              id="invite-email"
              type="email"
              autoComplete="off"
              value={inviteEmail}
              onChange={(e) => setInviteEmail(e.target.value)}
              disabled={inviteSubmitting}
              required
            />
          </div>
          <div className="team-form-row">
            <label htmlFor="invite-password">{t('team.invitePassword')}</label>
            <input
              id="invite-password"
              type="password"
              autoComplete="new-password"
              value={invitePassword}
              onChange={(e) => setInvitePassword(e.target.value)}
              disabled={inviteSubmitting}
              required
              minLength={6}
            />
          </div>
          <div className="team-form-row">
            <label htmlFor="invite-display">{t('team.inviteDisplayName')}</label>
            <input
              id="invite-display"
              type="text"
              value={inviteDisplayName}
              onChange={(e) => setInviteDisplayName(e.target.value)}
              disabled={inviteSubmitting}
              placeholder={t('team.inviteDisplayPlaceholder')}
            />
          </div>
          <div className="team-form-row">
            <label htmlFor="invite-staff">{t('team.inviteStaffId')}</label>
            <input
              id="invite-staff"
              type="text"
              value={inviteStaffId}
              onChange={(e) => setInviteStaffId(e.target.value)}
              disabled={inviteSubmitting}
              placeholder={t('team.inviteStaffPlaceholder')}
            />
          </div>
          {inviteError && <div className="team-invite-msg team-invite-error">{inviteError}</div>}
          {inviteSuccess && <div className="team-invite-msg team-invite-success">{inviteSuccess}</div>}
          <button type="submit" className="team-invite-submit" disabled={inviteSubmitting}>
            {inviteSubmitting ? t('team.inviteSubmitting') : t('team.inviteSubmit')}
          </button>
        </form>
      </section>

      {team.length === 0 ? (
        <div className="empty-state">{t('team.empty')}</div>
      ) : (
        <div className="team-table-wrap">
          <table className="team-table">
            <thead>
              <tr>
                <th>{t('team.thName')}</th>
                <th>{t('team.thEmail')}</th>
                <th>{t('team.thStaffId')}</th>
                <th>{t('team.thRole')}</th>
              </tr>
            </thead>
            <tbody>
              {team.map((u) => (
                <tr key={u.id}>
                  <td>{u.display_name || '—'}</td>
                  <td>{u.email || '—'}</td>
                  <td>{u.staff_id || '—'}</td>
                  <td>
                    <span className={`role-badge role-${(u.role || '').toLowerCase()}`}>
                      {u.role || '—'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
