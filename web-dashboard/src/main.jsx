import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import App from './App'
import { AuthProvider } from './context/AuthContext'
import { ThemeProvider } from './context/ThemeContext'
import { SearchProvider } from './context/SearchContext'
import { LocaleProvider } from './context/LocaleContext'
import { PendingReferralsProvider } from './context/PendingReferralsContext'
import './App.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <LocaleProvider>
        <ThemeProvider>
          <AuthProvider>
            <PendingReferralsProvider>
              <SearchProvider>
                <App />
              </SearchProvider>
            </PendingReferralsProvider>
          </AuthProvider>
        </ThemeProvider>
      </LocaleProvider>
    </BrowserRouter>
  </React.StrictMode>
)
