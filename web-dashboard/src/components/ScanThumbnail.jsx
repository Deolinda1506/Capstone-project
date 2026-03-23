import { useEffect, useRef, useState } from 'react'
import { fetchScanImageBlob } from '../api/client'
import './ScanThumbnail.css'

/**
 * Loads scan image with Bearer auth. variant controls layout (thumb vs detail hero).
 */
export default function ScanThumbnail({
  scanId,
  hasImage,
  variant = 'thumb',
  alt = '',
  className = '',
}) {
  const [url, setUrl] = useState(null)
  const [err, setErr] = useState(false)
  const [loading, setLoading] = useState(false)
  const urlRef = useRef(null)

  useEffect(() => {
    if (!hasImage || !scanId) {
      setUrl(null)
      setErr(false)
      setLoading(false)
      return undefined
    }

    let cancelled = false
    setLoading(true)
    setErr(false)
    fetchScanImageBlob(scanId)
      .then((blob) => {
        if (cancelled) return
        if (urlRef.current) URL.revokeObjectURL(urlRef.current)
        const u = URL.createObjectURL(blob)
        urlRef.current = u
        setUrl(u)
      })
      .catch(() => {
        if (!cancelled) setErr(true)
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })

    return () => {
      cancelled = true
      if (urlRef.current) {
        URL.revokeObjectURL(urlRef.current)
        urlRef.current = null
      }
    }
  }, [scanId, hasImage])

  const rootClass = `scan-thumbnail scan-thumbnail--${variant} ${className}`.trim()

  if (!hasImage) {
    return (
      <div className={rootClass}>
        <span className="scan-thumbnail__empty">—</span>
      </div>
    )
  }

  return (
    <div className={rootClass}>
      {err && <span className="scan-thumbnail__err" title={alt} />}
      {!err && loading && !url && <span className="scan-thumbnail__loading" />}
      {url && !err && <img src={url} alt={alt} className="scan-thumbnail__img" />}
    </div>
  )
}
