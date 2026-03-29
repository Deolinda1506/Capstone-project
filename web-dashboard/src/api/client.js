import { API_BASE } from '../context/AuthContext'

function formatDetail(detail) {
  if (typeof detail === 'string') return detail
  if (Array.isArray(detail)) {
    return detail.map((d) => (typeof d === 'object' && d?.msg ? d.msg : String(d))).join('; ')
  }
  return null
}

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
    throw new Error(formatDetail(err.detail) || `Request failed: ${res.status}`)
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

/** Public endpoint — no JWT so latency still loads if list calls fail (e.g. expired session). */
export async function getLatencyStats() {
  const url = `${API_BASE}/latency`
  const res = await fetch(url, { headers: { Accept: 'application/json' } })
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: res.statusText }))
    throw new Error(formatDetail(err.detail) || `Request failed: ${res.status}`)
  }
  return res.json()
}

export async function fetchScanImageBlob(scanId) {
  const token = localStorage.getItem('carotidcheck_token')
  const res = await fetch(`${API_BASE}/scans/${scanId}/image`, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  })
  if (!res.ok) {
    let detail = ''
    try {
      const j = await res.json()
      detail = typeof j.detail === 'string' ? j.detail : ''
    } catch {
      detail = res.statusText || ''
    }
    throw new Error(detail || `Failed to load image (${res.status})`)
  }
  return res.blob()
}

export async function getTeam() {
  return apiRequest('/auth/team')
}

/** Admin only: invite clinician or CHW to the same organization. */
export async function inviteUser({ email, password, display_name, role, staff_id }) {
  return apiRequest('/auth/invite-user', {
    method: 'POST',
    body: JSON.stringify({
      email: email.trim(),
      password,
      display_name: display_name?.trim() || null,
      role: role || 'clinician',
      staff_id: staff_id?.trim() || null,
    }),
  })
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
