import { useState, useEffect, useMemo } from 'react'
import { Link } from 'react-router-dom'
import { useSearch } from '../context/SearchContext'
import { useLocale } from '../context/LocaleContext'
import { getHighRisk, getScansWithResults, getLatencyStats } from '../api/client'
import ScanThumbnail from '../components/ScanThumbnail'
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
} from 'recharts'
import './DashboardPage.css'

const RISK_COLORS = { Low: '#22c55e', Moderate: '#f59e0b', High: '#dc2626' }

export default function DashboardPage() {
  const { searchQuery } = useSearch()
  const { t, dateLocaleTag } = useLocale()
  const [highRisk, setHighRisk] = useState([])
  const [allScans, setAllScans] = useState([])
  const [latency, setLatency] = useState({
    count: 0,
    mean_sec: null,
    min_sec: null,
    max_sec: null,
  })
  const [loading, setLoading] = useState(true)
  /** @type {['all' | 'pending' | 'reviewed', React.Dispatch<React.SetStateAction<'all' | 'pending' | 'reviewed'>>]} */
  const [reviewTab, setReviewTab] = useState(
    /** @type {'all' | 'pending' | 'reviewed'} */ ('pending'),
  )

  useEffect(() => {
    const nameFilter = searchQuery.trim()
    setLoading(true)
    Promise.all([
      getHighRisk(100, nameFilter, reviewTab),
      getScansWithResults(200, nameFilter),
      getLatencyStats(),
    ])
      .then(([hr, scans, lat]) => {
        setHighRisk(hr)
        setAllScans(scans)
        setLatency(
          lat && typeof lat === 'object'
            ? {
                count: Number(lat.count || 0),
                mean_sec: typeof lat.mean_sec === 'number' ? lat.mean_sec : null,
                min_sec: typeof lat.min_sec === 'number' ? lat.min_sec : null,
                max_sec: typeof lat.max_sec === 'number' ? lat.max_sec : null,
              }
            : { count: 0, mean_sec: null, min_sec: null, max_sec: null },
        )
      })
      .catch(() => {
        setHighRisk([])
        setAllScans([])
        setLatency({ count: 0, mean_sec: null, min_sec: null, max_sec: null })
      })
      .finally(() => setLoading(false))
  }, [searchQuery, reviewTab])

  const filteredHighRisk = useMemo(() => {
    if (!searchQuery.trim()) return highRisk
    const q = searchQuery.toLowerCase()
    return highRisk.filter(
      (r) =>
        r.patient_name?.toLowerCase().includes(q) ||
        r.patient_identifier?.toLowerCase().includes(q) ||
        r.scan_id?.toLowerCase().includes(q) ||
        r.patient_id?.toLowerCase().includes(q),
    )
  }, [highRisk, searchQuery])

  const filteredAllScans = useMemo(() => {
    if (!searchQuery.trim()) return allScans
    const q = searchQuery.toLowerCase()
    return allScans.filter(
      (s) =>
        s.patient_name?.toLowerCase().includes(q) ||
        s.patient_identifier?.toLowerCase().includes(q) ||
        s.scan_id?.toLowerCase().includes(q) ||
        s.patient_id?.toLowerCase().includes(q),
    )
  }, [allScans, searchQuery])

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
      label: new Date(r.date).toLocaleDateString(dateLocaleTag, { month: 'short', day: 'numeric' }),
    }))
  }, [allScans, dateLocaleTag])

  const reviewTabs = useMemo(
    () => [
      { id: 'pending', label: t('dashboard.tabPending') },
      { id: 'reviewed', label: t('dashboard.tabReviewed') },
      { id: 'all', label: t('dashboard.tabAll') },
    ],
    [t],
  )

  if (loading)
    return (
      <div className="dashboard">
        <div className="dashboard-loading">{t('dashboard.loading')}</div>
      </div>
    )

  return (
    <div className="dashboard">
      <h1 className="dashboard-title">{t('dashboard.title')}</h1>

      <div className="dashboard-charts">
        <div className="chart-card">
          <h3>{t('dashboard.riskDistribution')}</h3>
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
                  {riskDistribution.map((entry) => (
                    <Cell key={entry.name} fill={RISK_COLORS[entry.name] || '#94a3b8'} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
        <div className="chart-card">
          <h3>{t('dashboard.scansPerDay')}</h3>
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
        <div className="chart-card">
          <h3>{t('dashboard.inferenceLatency')}</h3>
          <div className="latency-card-body">
            <div className="latency-count">
              {t('dashboard.latencySamples')}: <strong>{latency.count}</strong>
            </div>
            {latency.count > 0 ? (
              <div className="latency-grid">
                <div className="latency-stat">
                  <span>{t('dashboard.latencyMean')}</span>
                  <strong>{latency.mean_sec?.toFixed(3)} s</strong>
                </div>
                <div className="latency-stat">
                  <span>{t('dashboard.latencyMin')}</span>
                  <strong>{latency.min_sec?.toFixed(3)} s</strong>
                </div>
                <div className="latency-stat">
                  <span>{t('dashboard.latencyMax')}</span>
                  <strong>{latency.max_sec?.toFixed(3)} s</strong>
                </div>
              </div>
            ) : (
              <div className="latency-empty">{t('dashboard.latencyEmpty')}</div>
            )}
          </div>
        </div>
      </div>

      <section className="analyses-section">
        <h2>{t('dashboard.analysesTitle')}</h2>
        <p className="analyses-section-hint">{t('dashboard.analysesHint')}</p>
        {filteredAllScans.length === 0 ? (
          <div className="empty-state">
            {t('dashboard.analysesEmpty')}
            {searchQuery ? t('dashboard.emptySearch') : ''}.
          </div>
        ) : (
          <div className="analyses-table-wrap">
            <table className="analyses-table">
              <thead>
                <tr>
                  <th className="col-preview">{t('dashboard.colPreview')}</th>
                  <th>{t('dashboard.colPatient')}</th>
                  <th>{t('dashboard.colPatientId')}</th>
                  <th>{t('dashboard.colImt')}</th>
                  <th>{t('dashboard.colRisk')}</th>
                  <th>{t('dashboard.colReferral')}</th>
                  <th>{t('dashboard.colDate')}</th>
                  <th>{t('dashboard.colAction')}</th>
                </tr>
              </thead>
              <tbody>
                {filteredAllScans.map((s) => (
                  <tr key={s.scan_id}>
                    <td className="col-preview">
                      <ScanThumbnail
                        scanId={s.scan_id}
                        hasImage={s.has_image}
                        alt=""
                      />
                    </td>
                    <td>{s.patient_name || '—'}</td>
                    <td>
                      <code className="analyses-id">{s.patient_identifier}</code>
                    </td>
                    <td>{s.imt_mm != null ? `${s.imt_mm} mm` : '—'}</td>
                    <td>
                      <span className={`risk-badge risk-${(s.risk_level || '').toLowerCase()}`}>
                        {s.risk_level || '—'}
                      </span>
                    </td>
                    <td>
                      {s.is_high_risk ? (
                        <span
                          className={`review-pill ${s.clinician_review_status === 'reviewed' ? 'reviewed' : 'pending'}`}
                        >
                          {s.clinician_review_status === 'reviewed'
                            ? t('dashboard.reviewed')
                            : t('dashboard.pending')}
                        </span>
                      ) : (
                        <span className="review-pill na">—</span>
                      )}
                    </td>
                    <td className="analyses-date">
                      {s.created_at
                        ? new Date(s.created_at).toLocaleString(dateLocaleTag)
                        : '—'}
                    </td>
                    <td>
                      <Link to={`/referral/${s.scan_id}`} className="analyses-open">
                        {t('dashboard.openAnalysis')}
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <section className="referrals-section">
        <h2>{t('dashboard.referralsTitle')}</h2>
        <p className="referrals-section-hint">{t('dashboard.referralsHint')}</p>
        <div className="review-tabs" role="tablist" aria-label={t('dashboard.referralsTitle')}>
          {reviewTabs.map(({ id, label }) => (
            <button
              key={id}
              type="button"
              role="tab"
              aria-selected={reviewTab === id}
              className={reviewTab === id ? 'active' : ''}
              onClick={() => setReviewTab(id)}
            >
              {label}
            </button>
          ))}
        </div>
        {filteredHighRisk.length === 0 ? (
          <div className="empty-state">
            {t('dashboard.empty')}
            {searchQuery ? t('dashboard.emptySearch') : ''}.
          </div>
        ) : (
          <div className="referrals-grid">
            {filteredHighRisk.map((r) => (
              <Link key={r.scan_id} to={`/referral/${r.scan_id}`} className="referral-card">
                <div className="referral-card-inner">
                  <div className="referral-card-thumb" aria-hidden>
                    <ScanThumbnail scanId={r.scan_id} hasImage={r.has_image} alt="" />
                  </div>
                  <div className="referral-card-body">
                    <div className="referral-header">
                      <span className="referral-patient">
                        {r.patient_name || r.patient_identifier}
                      </span>
                      <span className="referral-badges">
                        <span
                          className={`review-status-badge ${r.clinician_review_status === 'reviewed' ? 'reviewed' : 'pending'}`}
                        >
                          {r.clinician_review_status === 'reviewed'
                            ? t('dashboard.reviewed')
                            : t('dashboard.pending')}
                        </span>
                        <span className={`risk-badge risk-${(r.risk_level || '').toLowerCase()}`}>
                          {r.risk_level || 'High'}
                        </span>
                      </span>
                    </div>
                    <div className="referral-meta">
                      {r.patient_name && (
                        <span className="referral-id">
                          {t('dashboard.id')} {r.patient_identifier}
                        </span>
                      )}
                      {r.patient_age != null && (
                        <span className="referral-age">
                          {t('dashboard.age')} {r.patient_age}
                        </span>
                      )}
                      IMT: {r.imt_mm} mm
                      {r.plaque_detected && <span className="plaque">{t('dashboard.plaque')}</span>}
                    </div>
                    <div className="referral-date">
                      {r.created_at ? new Date(r.created_at).toLocaleString(dateLocaleTag) : '—'}
                    </div>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </section>
    </div>
  )
}
