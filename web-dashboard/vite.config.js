import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

/** @type {import('vite').UserConfigExport} */
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const proxyTarget =
    env.DEV_PROXY_TARGET?.trim() ||
    env.VITE_API_URL?.trim() ||
    'http://localhost:8000'

  return {
    plugins: [react()],
    server: {
      port: 5173,
      proxy: {
        '/auth': { target: proxyTarget, changeOrigin: true, secure: true },
        '/patients': { target: proxyTarget, changeOrigin: true, secure: true },
        '/scans': { target: proxyTarget, changeOrigin: true, secure: true },
        '/health': { target: proxyTarget, changeOrigin: true, secure: true },
        '/ml-status': { target: proxyTarget, changeOrigin: true, secure: true },
        '/latency': { target: proxyTarget, changeOrigin: true, secure: true },
      },
    },
  }
})
