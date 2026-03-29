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
  const [errMsg, setErrMsg] = useState(/** @type {string | null} */ (null))
  const [loading, setLoading] = useState(false)
  const urlRef = useRef(null)

  useEffect(() => {
    if (!hasImage || !scanId) {
      setUrl(null)
      setErrMsg(null)
      setLoading(false)
      return undefined
    }

    let cancelled = false
    setLoading(true)
    setErrMsg(null)
    fetchScanImageBlob(scanId)
      .then((blob) => {
        if (cancelled) return
        if (urlRef.current) URL.revokeObjectURL(urlRef.current)
        const u = URL.createObjectURL(blob)
        urlRef.current = u
        setUrl(u)
      })
      .catch((e) => {
        if (!cancelled) {
          setErrMsg(e instanceof Error ? e.message : 'Failed to load image')
        }
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
      {errMsg && (
        <div className="scan-thumbnail__err-wrap">
          <span className="scan-thumbnail__err" title={errMsg} aria-hidden />
          <p className="scan-thumbnail__err-msg">{errMsg}</p>
        </div>
      )}
      {!errMsg && loading && !url && <span className="scan-thumbnail__loading" />}
      {url && !errMsg && <img src={url} alt={alt} className="scan-thumbnail__img" />}
    </div>
  )
}
