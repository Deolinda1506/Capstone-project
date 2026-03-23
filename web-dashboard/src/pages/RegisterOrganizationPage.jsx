import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { API_BASE } from '../context/AuthContext'
import './RegisterOrganizationPage.css'

export default function RegisterOrganizationPage() {
  const [form, setForm] = useState({
    admin_email: '',
    password: '',
    display_name: '',
    hospital_name: '',
    province: '',
    district: '',
    sector: '',
  })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()

  const handleChange = (e) => {
    setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const url = `${API_BASE}/auth/register-hospital`
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      })
      const text = await res.text()
      let data = {}
      if (text) {
        try {
          data = JSON.parse(text)
        } catch {
          data = { detail: text.slice(0, 200) }
        }
      }
      if (!res.ok) {
        const msg =
          typeof data.detail === 'string'
            ? data.detail
            : Array.isArray(data.detail)
              ? data.detail.map((d) => d.msg || d).join('; ')
              : `Server error (${res.status})`
        throw new Error(msg)
      }
      localStorage.setItem('carotidcheck_token', data.access_token)
      localStorage.setItem('carotidcheck_user', JSON.stringify(data.user))
      navigate('/dashboard')
      window.location.reload()
    } catch (err) {
      const name = err?.name || ''
      const msg = err?.message || ''
      const isNetwork =
        name === 'TypeError' ||
        msg === 'Failed to fetch' ||
        msg.includes('NetworkError') ||
        msg.includes('Load failed')
      setError(
        isNetwork
          ? `Cannot reach the API (${API_BASE || 'same-origin / Vite proxy'}). For local dev, use an empty VITE_API_URL and set DEV_PROXY_TARGET=https://carotidcheck-api.onrender.com in web-dashboard/.env, then restart npm run dev.`
          : msg || 'Registration failed',
      )
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="register-page">
      <div className="register-card">
        <h1>Register organization</h1>
        <p className="register-subtitle">Create your hospital or clinic account</p>
        <form onSubmit={handleSubmit} className="register-form">
          <label>
            Admin email *
            <input
              type="email"
              name="admin_email"
              value={form.admin_email}
              onChange={handleChange}
              placeholder="admin@example.com"
              required
            />
          </label>
          <label>
            Password *
            <input
              type="password"
              name="password"
              value={form.password}
              onChange={handleChange}
              placeholder="At least 6 characters"
              required
              minLength={6}
            />
          </label>
          <label>
            Display name
            <input
              type="text"
              name="display_name"
              value={form.display_name}
              onChange={handleChange}
              placeholder="Your name"
            />
          </label>
          <label>
            Hospital / facility name *
            <input
              type="text"
              name="hospital_name"
              value={form.hospital_name}
              onChange={handleChange}
              placeholder="Gasabo District Hospital"
              required
            />
          </label>
          <label>
            Province
            <input
              type="text"
              name="province"
              value={form.province}
              onChange={handleChange}
              placeholder="Kigali"
            />
          </label>
          <label>
            District
            <input
              type="text"
              name="district"
              value={form.district}
              onChange={handleChange}
              placeholder="Gasabo"
            />
          </label>
          <label>
            Sector
            <input
              type="text"
              name="sector"
              value={form.sector}
              onChange={handleChange}
              placeholder="Kimironko"
            />
          </label>
          {error && <div className="register-error">{error}</div>}
          <button type="submit" className="btn btn-primary btn-block" disabled={loading}>
            {loading ? 'Creating…' : 'Register'}
          </button>
        </form>
        <p className="register-footer">
          Already have an account? <Link to="/login">Log in</Link>
        </p>
      </div>
    </div>
  )
}
