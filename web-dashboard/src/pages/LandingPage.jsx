import { Link } from 'react-router-dom'
import { useLocale } from '../context/LocaleContext'
import './LandingPage.css'

export default function LandingPage() {
  const { t } = useLocale()

  return (
    <div className="landing">
      <header className="landing-header">
        <div className="landing-nav">
          <span className="landing-logo">{t('landing.logo')}</span>
          <div className="landing-nav-links">
            <Link to="/login">{t('landing.login')}</Link>
            <Link to="/register-organization" className="btn btn-primary">
              {t('landing.registerOrg')}
            </Link>
          </div>
        </div>
      </header>

      <section className="hero">
        <h1>{t('landing.heroTitle')}</h1>
        <p className="hero-sub">{t('landing.heroSub')}</p>
        <div className="hero-cta">
          <Link to="/register-organization" className="btn btn-primary btn-lg">
            {t('landing.getStarted')}
          </Link>
          <Link to="/login" className="btn btn-outline btn-lg">
            {t('landing.login')}
          </Link>
        </div>
      </section>

      <section className="features">
        <h2>{t('landing.featuresTitle')}</h2>
        <div className="features-grid">
          <div className="feature-card">
            <div className="feature-icon">📊</div>
            <h3>{t('landing.f1Title')}</h3>
            <p>{t('landing.f1Body')}</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">🏥</div>
            <h3>{t('landing.f2Title')}</h3>
            <p>{t('landing.f2Body')}</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">📱</div>
            <h3>{t('landing.f3Title')}</h3>
            <p>{t('landing.f3Body')}</p>
          </div>
        </div>
      </section>

      <section className="cta">
        <h2>{t('landing.ctaTitle')}</h2>
        <p>{t('landing.ctaSub')}</p>
        <div className="cta-buttons">
          <Link to="/register-organization" className="btn btn-primary btn-lg">
            {t('landing.registerOrg')}
          </Link>
          <Link to="/login" className="btn btn-outline btn-lg">
            {t('landing.login')}
          </Link>
        </div>
      </section>

      <footer className="landing-footer">
        <p>{t('landing.footer')}</p>
      </footer>
    </div>
  )
}
