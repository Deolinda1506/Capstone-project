import { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import { getScanResult, patchScanReview } from '../api/client'
import { useAuth } from '../context/AuthContext'
import { useLocale } from '../context/LocaleContext'
import { usePendingReferrals } from '../context/PendingReferralsContext'
import ScanThumbnail from '../components/ScanThumbnail'
import './ReferralPage.css'

export default function ReferralPage() {
  const { scanId } = useParams()
  const { user } = useAuth()
  const { t, dateLocaleTag } = useLocale()
  const { refreshPending } = usePendingReferrals()
  const [result, setResult] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [notes, setNotes] = useState('')
  const [saving, setSaving] = useState(false)
  const [saveError, setSaveError] = useState('')

  const canReview =
    user && ['admin', 'clinician'].includes((user.role || '').toLowerCase())

  useEffect(() => {
    setLoading(true)
    getScanResult(scanId)
      .then((data) => {
        setResult(data)
        setNotes(data.clinical_notes || '')
      })
      .catch((err) => {
        setError(err.message || 'Failed to load referral')
        setResult(null)
      })
      .finally(() => setLoading(false))
  }, [scanId])

  if (loading) {
    return (
      <div className="referral-page">
        <div className="referral-loading">{t('referral.loading')}</div>
      </div>
    )
  }
  if (error) {
    return (
      <div className="referral-page">
        <div className="referral-error">{error}</div>
      </div>
    )
  }
  if (!result) return null

  const isReviewed = result.clinician_review_status === 'reviewed'
  const isHighRisk = result.is_high_risk
  const pageTitleKey = isHighRisk ? 'referral.title' : 'referral.analysisTitle'

  const handleSaveReview = async (status) => {
    if (!canReview || !isHighRisk) return
    setSaving(true)
    setSaveError('')
    try {
      const updated = await patchScanReview(scanId, {
        status,
        clinical_notes: notes,
      })
      setResult(updated)
      setNotes(updated.clinical_notes || '')
      await refreshPending()
    } catch (e) {
      setSaveError(e.message || 'Could not save')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="referral-page">
      <div className="referral-back">
        <Link to="/dashboard">{t('referral.back')}</Link>
      </div>
      <h1>
        {t(pageTitleKey)} {result.patient_name || result.patient_identifier}
      </h1>
      {isHighRisk && (
        <div className="review-banner">
          <span className={`review-status-badge ${isReviewed ? 'reviewed' : 'pending'}`}>
            {isReviewed ? t('referral.reviewed') : t('referral.pendingReview')}
          </span>
          {result.clinician_reviewed_at && (
            <span className="review-meta">
              {t('referral.updated')}{' '}
              {new Date(result.clinician_reviewed_at).toLocaleString(dateLocaleTag)}
            </span>
          )}
        </div>
      )}

      <div className="referral-layout">
        <div className="referral-details">
          <section className="detail-card">
            <h2>{t('referral.patient')}</h2>
            <dl>
              {result.patient_name && (
                <>
                  <dt>{t('referral.name')}</dt>
                  <dd>{result.patient_name}</dd>
                </>
              )}
              {result.patient_age != null && (
                <>
                  <dt>{t('referral.age')}</dt>
                  <dd>
                    {result.patient_age} {t('referral.years')}
                  </dd>
                </>
              )}
              <dt>{t('referral.patientId')}</dt>
              <dd>{result.patient_identifier}</dd>
              <dt>{t('referral.scanId')}</dt>
              <dd>
                <code>{result.scan_id}</code>
              </dd>
              <dt>{t('referral.date')}</dt>
              <dd>
                {result.created_at ? new Date(result.created_at).toLocaleString(dateLocaleTag) : '—'}
              </dd>
            </dl>
          </section>
          <section className="detail-card">
            <h2>{t('referral.results')}</h2>
            <dl>
              <dt>{t('referral.imt')}</dt>
              <dd>
                <strong>{result.imt_mm != null ? `${result.imt_mm} mm` : '—'}</strong>
              </dd>
              <dt>{t('referral.riskLevel')}</dt>
              <dd>
                <span className={`risk-badge risk-${(result.risk_level || '').toLowerCase()}`}>
                  {result.risk_level || 'High'}
                </span>
              </dd>
              <dt>{t('referral.plaqueDetected')}</dt>
              <dd>{result.plaque_detected ? t('referral.yes') : t('referral.no')}</dd>
              {result.stenosis_pct != null && (
                <>
                  <dt>{t('referral.stenosis')}</dt>
                  <dd>{result.stenosis_pct}%</dd>
                </>
              )}
              {result.clinical_notes && !(canReview && isHighRisk) && (
                <>
                  <dt>{t('referral.clinicalNotes')}</dt>
                  <dd className="clinical-notes-display">{result.clinical_notes}</dd>
                </>
              )}
            </dl>
          </section>
          {canReview && isHighRisk && (
            <section className="detail-card review-actions-card">
              <h2>{t('referral.clinicianReview')}</h2>
              <p className="review-help">{t('referral.reviewHelp')}</p>
              <label className="review-notes-label" htmlFor="clinical-notes">
                {t('referral.notesLabel')}
              </label>
              <textarea
                id="clinical-notes"
                className="review-notes-input"
                rows={4}
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder={t('referral.notesPlaceholder')}
                disabled={saving}
              />
              {saveError && <div className="review-save-error">{saveError}</div>}
              <div className="review-buttons">
                {!isReviewed ? (
                  <button
                    type="button"
                    className="btn-primary"
                    disabled={saving}
                    onClick={() => handleSaveReview('reviewed')}
                  >
                    {saving ? t('referral.saving') : t('referral.markReviewed')}
                  </button>
                ) : (
                  <button
                    type="button"
                    className="btn-secondary"
                    disabled={saving}
                    onClick={() => handleSaveReview('pending')}
                  >
                    {saving ? t('referral.saving') : t('referral.reopen')}
                  </button>
                )}
              </div>
            </section>
          )}
        </div>
        <div className="referral-image">
          {result.has_image ? (
            <ScanThumbnail
              scanId={scanId}
              hasImage
              variant="hero"
              alt={t('referral.scanAlt')}
            />
          ) : (
            <div className="image-placeholder">{t('referral.noImage')}</div>
          )}
        </div>
      </div>
    </div>
  )
}
