import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuth } from './context/AuthContext'
import { useLocale } from './context/LocaleContext'
import AppLayout from './components/AppLayout'
import LandingPage from './pages/LandingPage'
import LoginPage from './pages/LoginPage'
import ForgotPasswordPage from './pages/ForgotPasswordPage'
import ResetPasswordPage from './pages/ResetPasswordPage'
import RegisterOrganizationPage from './pages/RegisterOrganizationPage'
import DashboardPage from './pages/DashboardPage'
import SettingsPage from './pages/SettingsPage'
import TeamPage from './pages/TeamPage'
import ReferralPage from './pages/ReferralPage'

function ProtectedRoute({ children }) {
  const { user, loading } = useAuth()
  const { t } = useLocale()
  if (loading) return <div className="app-loading">{t('app.loading')}</div>
  if (!user) return <Navigate to="/login" replace />
  return children
}

function PublicOnlyRoute({ children }) {
  const { user, loading } = useAuth()
  const { t } = useLocale()
  if (loading) return <div className="app-loading">{t('app.loading')}</div>
  if (user) return <Navigate to="/dashboard" replace />
  return children
}

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<LandingPage />} />
      <Route path="/login" element={<PublicOnlyRoute><LoginPage /></PublicOnlyRoute>} />
      <Route path="/forgot-password" element={<PublicOnlyRoute><ForgotPasswordPage /></PublicOnlyRoute>} />
      <Route path="/reset-password" element={<ResetPasswordPage />} />
      <Route path="/register-organization" element={<PublicOnlyRoute><RegisterOrganizationPage /></PublicOnlyRoute>} />
      <Route
        path="/dashboard"
        element={
          <ProtectedRoute>
            <AppLayout><DashboardPage /></AppLayout>
          </ProtectedRoute>
        }
      />
      <Route
        path="/settings"
        element={
          <ProtectedRoute>
            <AppLayout><SettingsPage /></AppLayout>
          </ProtectedRoute>
        }
      />
      <Route
        path="/team"
        element={
          <ProtectedRoute>
            <AppLayout><TeamPage /></AppLayout>
          </ProtectedRoute>
        }
      />
      <Route
        path="/referral/:scanId"
        element={
          <ProtectedRoute>
            <AppLayout><ReferralPage /></AppLayout>
          </ProtectedRoute>
        }
      />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
