import { useState, useEffect } from 'react'
import { getTeam } from '../api/client'
import './TeamPage.css'

export default function TeamPage() {
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

  if (loading) return <div className="team-page"><div className="team-loading">Loading team…</div></div>
  if (error) return <div className="team-page"><div className="team-error">{error}</div></div>

  return (
    <div className="team-page">
      <h1>Team</h1>
      <p className="team-subtitle">Clinicians and CHWs in your organization (admin view)</p>
      {team.length === 0 ? (
        <div className="empty-state">No team members yet.</div>
      ) : (
        <div className="team-table-wrap">
          <table className="team-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Staff ID</th>
                <th>Role</th>
              </tr>
            </thead>
            <tbody>
              {team.map((u) => (
                <tr key={u.id}>
                  <td>{u.display_name || '—'}</td>
                  <td>{u.email || '—'}</td>
                  <td>{u.staff_id || '—'}</td>
                  <td><span className={`role-badge role-${(u.role || '').toLowerCase()}`}>{u.role || '—'}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
