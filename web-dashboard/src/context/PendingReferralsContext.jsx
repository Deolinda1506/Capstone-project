import {
  createContext,
  useContext,
  useState,
  useEffect,
  useRef,
  useCallback,
  useMemo,
} from 'react'
import { getHighRisk } from '../api/client'
import { useLocale } from './LocaleContext'
import { useAuth } from './AuthContext'

const PendingReferralsContext = createContext(null)

const POLL_MS = 45_000
const DESKTOP_NOTIFY_KEY = 'cc_desktop_notify'

export function PendingReferralsProvider({ children }) {
  const { user } = useAuth()
  const { t } = useLocale()
  const [highRisk, setHighRisk] = useState([])
  const [alertBanner, setAlertBanner] = useState(null)
  const prevPendingIdsRef = useRef(null)
  const tRef = useRef(t)
  tRef.current = t

  const fetchPending = useCallback(async () => {
    if (!user) {
      setHighRisk([])
      return
    }
    const list = await getHighRisk(50, '', 'pending').catch(() => [])
    const ids = list.map((r) => r.scan_id).filter(Boolean)
    setHighRisk(list)

    if (prevPendingIdsRef.current === null) {
      prevPendingIdsRef.current = new Set(ids)
      return
    }

    const prev = prevPendingIdsRef.current
    const newArrivals = ids.filter((id) => !prev.has(id))
    prevPendingIdsRef.current = new Set(ids)

    if (newArrivals.length === 0) return

    setAlertBanner({ count: newArrivals.length })

    try {
      if (
        typeof Notification !== 'undefined' &&
        localStorage.getItem(DESKTOP_NOTIFY_KEY) === '1' &&
        Notification.permission === 'granted'
      ) {
        const tr = tRef.current
        new Notification(tr('notify.title'), {
          body: tr('notify.body', { count: newArrivals.length }),
          tag: `cc-pending-${newArrivals[0]}`,
        })
      }
    } catch {
      /* ignore */
    }
  }, [user])

  const refreshPending = useCallback(async () => {
    if (!user) return
    await fetchPending()
  }, [user, fetchPending])

  useEffect(() => {
    if (!user) {
      setHighRisk([])
      prevPendingIdsRef.current = null
      return undefined
    }
    prevPendingIdsRef.current = null
    let cancelled = false
    const run = () => {
      if (!cancelled) refreshPending()
    }
    run()
    const timer = setInterval(run, POLL_MS)
    return () => {
      cancelled = true
      clearInterval(timer)
    }
  }, [user, refreshPending])

  const value = useMemo(
    () => ({ highRisk, alertBanner, setAlertBanner, refreshPending }),
    [highRisk, alertBanner, refreshPending],
  )

  return (
    <PendingReferralsContext.Provider value={value}>{children}</PendingReferralsContext.Provider>
  )
}

export function usePendingReferrals() {
  const ctx = useContext(PendingReferralsContext)
  if (!ctx) {
    throw new Error('usePendingReferrals must be used within PendingReferralsProvider')
  }
  return ctx
}
