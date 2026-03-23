import { Link } from 'react-router-dom'
import './LandingPage.css'

export default function LandingPage() {
  return (
    <div className="landing">
      <header className="landing-header">
        <div className="landing-nav">
          <span className="landing-logo">CarotidCheck</span>
          <div className="landing-nav-links">
            <Link to="/login">Log in</Link>
            <Link to="/register-organization" className="btn btn-primary">Register organization</Link>
          </div>
        </div>
      </header>

      <section className="hero">
        <h1>AI-powered carotid ultrasound screening</h1>
        <p className="hero-sub">
          Stroke risk assessment for Rwanda. Community health workers capture scans, get instant IMT and risk levels, and refer high-risk patients to hospitals.
        </p>
        <div className="hero-cta">
          <Link to="/register-organization" className="btn btn-primary btn-lg">Get started</Link>
          <Link to="/login" className="btn btn-outline btn-lg">Log in</Link>
        </div>
      </section>

      <section className="features">
        <h2>Features</h2>
        <div className="features-grid">
          <div className="feature-card">
            <div className="feature-icon">📊</div>
            <h3>Instant risk stratification</h3>
            <p>IMT (intima-media thickness) and risk levels from carotid ultrasound in seconds.</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">🏥</div>
            <h3>Referral workflow</h3>
            <p>High-risk patients are flagged and referred seamlessly to district hospitals.</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">📱</div>
            <h3>Clinician dashboard</h3>
            <p>View high-risk referrals, analytics, and team management in one place.</p>
          </div>
        </div>
      </section>

      <section className="cta">
        <h2>Ready to get started?</h2>
        <p>Register your organization or log in to the clinician dashboard.</p>
        <div className="cta-buttons">
          <Link to="/register-organization" className="btn btn-primary btn-lg">Register organization</Link>
          <Link to="/login" className="btn btn-outline btn-lg">Log in</Link>
        </div>
      </section>

      <footer className="landing-footer">
        <p>© CarotidCheck — Stroke risk assessment for Rwanda</p>
      </footer>
    </div>
  )
}
