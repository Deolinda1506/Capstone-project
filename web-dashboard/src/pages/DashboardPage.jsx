import { useState, useEffect, useMemo } from 'react'
import { Link } from 'react-router-dom'
import { useSearch } from '../context/SearchContext'
import { getHighRisk, getScansWithResults } from '../api/client'
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from 'recharts'
import './DashboardPage.css'

const RISK_COLORS = { Low: '#22c55e', Moderate: '#f59e0b', High: '#dc2626' }

export default function DashboardPage() {
  const { searchQuery } = useSearch()
  const [highRisk, setHighRisk] = useState([])
  const [allScans, setAllScans] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const nameFilter = searchQuery.trim()
    Promise.all([
      getHighRisk(100, nameFilter),
      getScansWithResults(200, nameFilter),
    ])
      .then(([hr, scans]) => {
        setHighRisk(hr)
        setAllScans(scans)
      })
      .catch(() => {
        setHighRisk([])
        setAllScans([])
      })
      .finally(() => setLoading(false))
  }, [searchQuery])

  const filteredHighRisk = useMemo(() => {
    if (!searchQuery.trim()) return highRisk
    const q = searchQuery.toLowerCase()
    return highRisk.filter(
      (r) =>
        r.patient_name?.toLowerCase().includes(q) ||
        r.patient_identifier?.toLowerCase().includes(q) ||
        r.scan_id?.toLowerCase().includes(q) ||
        r.patient_id?.toLowerCase().includes(q)
    )
  }, [highRisk, searchQuery])

  const riskDistribution = useMemo(() => {
    const counts = { Low: 0, Moderate: 0, High: 0 }
    allScans.forEach((s) => {
      const level = s.risk_level || 'Low'
      if (counts[level] !== undefined) counts[level]++
    })
    return Object.entries(counts).map(([name, value]) => ({ name, value }))
  }, [allScans])

  const scansPerDay = useMemo(() => {
    const byDay = {}
    const now = new Date()
    for (let i = 13; i >= 0; i--) {
      const d = new Date(now)
      d.setDate(d.getDate() - i)
      const key = d.toISOString().slice(0, 10)
      byDay[key] = { date: key, scans: 0 }
    }
    allScans.forEach((s) => {
      if (!s.created_at) return
      const day = s.created_at.slice(0, 10)
      if (byDay[day]) byDay[day].scans++
    })
    return Object.values(byDay).map((r) => ({
      ...r,
      label: new Date(r.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
    }))
  }, [allScans])

  if (loading)
    return (
      <div className="dashboard">
        <div className="dashboard-loading">Loading dashboard…</div>
      </div>
    )

  return (
    <div className="dashboard">
      <h1 className="dashboard-title">Overview</h1>

      <div className="dashboard-charts">
        <div className="chart-card">
          <h3>Risk distribution</h3>
          <div className="chart-inner">
            <ResponsiveContainer width="100%" height={220}>
              <PieChart>
                <Pie
                  data={riskDistribution}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  label={({ name, value }) => `${name} (${value})`}
                >
                  {riskDistribution.map((entry, i) => (
                    <Cell key={entry.name} fill={RISK_COLORS[entry.name] || '#94a3b8'} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
        <div className="chart-card">
          <h3>Scans per day (last 14 days)</h3>
          <div className="chart-inner">
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={scansPerDay}>
                <XAxis dataKey="label" tick={{ fontSize: 11 }} />
                <YAxis allowDecimals={false} />
                <Tooltip />
                <Bar dataKey="scans" fill={RISK_COLORS.Moderate} radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      <section className="referrals-section">
        <h2>High-risk referrals</h2>
        {filteredHighRisk.length === 0 ? (
          <div className="empty-state">No high-risk referrals{searchQuery ? ' match your search' : ''}.</div>
        ) : (
          <div className="referrals-grid">
            {filteredHighRisk.map((r) => (
              <Link key={r.scan_id} to={`/referral/${r.scan_id}`} className="referral-card">
                <div className="referral-header">
                  <span className="referral-patient">
                    {r.patient_name || r.patient_identifier}
                  </span>
                  <span className={`risk-badge risk-${(r.risk_level || '').toLowerCase()}`}>
                    {r.risk_level || 'High'}
                  </span>
                </div>
                <div className="referral-meta">
                  {r.patient_name && (
                    <span className="referral-id">ID: {r.patient_identifier}</span>
                  )}
                  {r.patient_age != null && (
                    <span className="referral-age">Age: {r.patient_age}</span>
                  )}
                  IMT: {r.imt_mm} mm
                  {r.plaque_detected && <span className="plaque">Plaque detected</span>}
                </div>
                <div className="referral-date">
                  {r.created_at ? new Date(r.created_at).toLocaleString() : '—'}
                </div>
              </Link>
            ))}
          </div>
        )}
      </section>
    </div>
  )
}
