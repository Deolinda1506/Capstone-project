import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react'
import { STRINGS, SUPPORTED_LOCALES } from '../i18n/translations'

const LocaleContext = createContext(null)
const STORAGE_KEY = 'cc_locale'

export function LocaleProvider({ children }) {
  const [locale, setLocaleState] = useState(() => {
    try {
      const s = localStorage.getItem(STORAGE_KEY)
      if (s && SUPPORTED_LOCALES.includes(s)) return s
    } catch {
      /* ignore */
    }
    return 'en'
  })

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, locale)
    } catch {
      /* ignore */
    }
    document.documentElement.lang = locale
  }, [locale])

  const setLocale = useCallback((l) => {
    if (SUPPORTED_LOCALES.includes(l)) setLocaleState(l)
  }, [])

  const t = useCallback(
    (key, params) => {
      const dict = STRINGS[locale] || STRINGS.en
      let s = dict[key] ?? STRINGS.en[key] ?? key
      if (params && typeof s === 'string') {
        Object.entries(params).forEach(([k, v]) => {
          s = s.replace(new RegExp(`\\{${k}\\}`, 'g'), String(v))
        })
      }
      return s
    },
    [locale],
  )

  const dateLocaleTag = locale === 'fr' ? 'fr-FR' : locale === 'rw' ? 'rw-RW' : 'en-US'

  const value = useMemo(
    () => ({ locale, setLocale, t, dateLocaleTag }),
    [locale, setLocale, t, dateLocaleTag],
  )
  return <LocaleContext.Provider value={value}>{children}</LocaleContext.Provider>
}

export function useLocale() {
  const ctx = useContext(LocaleContext)
  if (!ctx) throw new Error('useLocale must be used within LocaleProvider')
  return ctx
}
