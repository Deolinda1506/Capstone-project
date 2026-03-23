import { useState, useEffect, useRef } from 'react'
import { useParams, Link } from 'react-router-dom'
import { getScanResult, fetchScanImageBlob } from '../api/client'
import './ReferralPage.css'

export default function ReferralPage() {
  const { scanId } = useParams()
  const [result, setResult] = useState(null)
  const [imageUrl, setImageUrl] = useState(null)
  const [imageError, setImageError] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const imageUrlRef = useRef(null)

  useEffect(() => {
    getScanResult(scanId)
      .then(setResult)
      .catch((err) => {
        setError(err.message || 'Failed to load referral')
        setResult(null)
      })
      .finally(() => setLoading(false))
  }, [scanId])

  useEffect(() => {
    if (!result?.has_image) return
    setImageError(false)
    fetchScanImageBlob(scanId)
      .then((blob) => {
        if (imageUrlRef.current) URL.revokeObjectURL(imageUrlRef.current)
        const url = URL.createObjectURL(blob)
        imageUrlRef.current = url
        setImageUrl(url)
      })
      .catch(() => setImageError(true))
    return () => {
      if (imageUrlRef.current) {
        URL.revokeObjectURL(imageUrlRef.current)
        imageUrlRef.current = null
      }
    }
  }, [scanId, result?.has_image])

  if (loading) return <div className="referral-page"><div className="referral-loading">Loading…</div></div>
  if (error) return <div className="referral-page"><div className="referral-error">{error}</div></div>
  if (!result) return null

  return (
    <div className="referral-page">
      <div className="referral-back">
        <Link to="/dashboard">← Back to dashboard</Link>
      </div>
      <h1>Referral: {result.patient_name || result.patient_identifier}</h1>

      <div className="referral-layout">
        <div className="referral-details">
          <section className="detail-card">
            <h2>Patient</h2>
            <dl>
              {result.patient_name && (
                <>
                  <dt>Name</dt>
                  <dd>{result.patient_name}</dd>
                </>
              )}
              {result.patient_age != null && (
                <>
                  <dt>Age</dt>
                  <dd>{result.patient_age} years</dd>
                </>
              )}
              <dt>Patient ID</dt>
              <dd>{result.patient_identifier}</dd>
              <dt>Scan ID</dt>
              <dd><code>{result.scan_id}</code></dd>
              <dt>Date</dt>
              <dd>{result.created_at ? new Date(result.created_at).toLocaleString() : '—'}</dd>
            </dl>
          </section>
          <section className="detail-card">
            <h2>Results</h2>
            <dl>
              <dt>IMT</dt>
              <dd><strong>{result.imt_mm} mm</strong></dd>
              <dt>Risk level</dt>
              <dd><span className={`risk-badge risk-${(result.risk_level || '').toLowerCase()}`}>{result.risk_level || 'High'}</span></dd>
              <dt>Plaque detected</dt>
              <dd>{result.plaque_detected ? 'Yes' : 'No'}</dd>
              {result.stenosis_pct != null && (
                <>
                  <dt>Stenosis</dt>
                  <dd>{result.stenosis_pct}%</dd>
                </>
              )}
            </dl>
          </section>
        </div>
        <div className="referral-image">
          {imageUrl && !imageError ? (
            <img src={imageUrl} alt="Scan overlay" onError={() => setImageError(true)} />
          ) : result.has_image && imageError ? (
            <div className="image-placeholder">Image failed to load</div>
          ) : (
            <div className="image-placeholder">No image available</div>
          )}
        </div>
      </div>
    </div>
  )
}
