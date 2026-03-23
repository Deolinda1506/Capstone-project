import { useState, useEffect } from 'react'
import { getTeam } from '../api/client'
import { useLocale } from '../context/LocaleContext'
import './TeamPage.css'

export default function TeamPage() {
  const { t } = useLocale()
  const [team, setTeam] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    getTeam()
      .then(setTeam)
      .catch((err) => {
        setError(err.message || 'Failed to load team')
        setTeam([])
      })
      .finally(() => setLoading(false))
  }, [])

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
