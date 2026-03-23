import { API_BASE } from '../context/AuthContext'

export async function apiRequest(path, options = {}) {
  const token = localStorage.getItem('carotidcheck_token')
  const url = `${API_BASE}${path}`
  const headers = {
    'Content-Type': 'application/json',
    ...(token && { Authorization: `Bearer ${token}` }),
    ...options.headers,
  }
  const res = await fetch(url, { ...options, headers })
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: res.statusText }))
    throw new Error(err.detail || `Request failed: ${res.status}`)
  }
  return res.json()
}

export async function getHighRisk(limit = 50, name = '', reviewStatus = 'all') {
  const params = new URLSearchParams({ limit })
  if (name?.trim()) params.set('name', name.trim())
  if (reviewStatus && reviewStatus !== 'all') params.set('review_status', reviewStatus)
  return apiRequest(`/scans/high-risk?${params}`)
}

export async function getScansWithResults(limit = 50, name = '') {
  const params = new URLSearchParams({ limit })
  if (name?.trim()) params.set('name', name.trim())
  return apiRequest(`/scans/with-results?${params}`)
}

export async function getScanResult(scanId) {
  return apiRequest(`/scans/${scanId}/result`)
}

export async function fetchScanImageBlob(scanId) {
  const token = localStorage.getItem('carotidcheck_token')
  const res = await fetch(`${API_BASE}/scans/${scanId}/image`, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  })
  if (!res.ok) throw new Error('Failed to load image')
  return res.blob()
}

export async function getTeam() {
  return apiRequest('/auth/team')
}

export async function patchScanReview(scanId, { status, clinical_notes: clinicalNotes }) {
  return apiRequest(`/scans/${scanId}/review`, {
    method: 'PATCH',
    body: JSON.stringify({
      status,
      clinical_notes: clinicalNotes?.trim() || null,
    }),
  })
}
