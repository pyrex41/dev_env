import { useState, useEffect } from 'react'
import './App.css'

function App() {
  const [apiStatus, setApiStatus] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

  useEffect(() => {
    const fetchStatus = async () => {
      try {
        const response = await fetch(`${API_URL}/api/status`)
        if (!response.ok) throw new Error('Failed to fetch API status')
        const data = await response.json()
        setApiStatus(data)
        setError(null)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchStatus()
  }, [API_URL])

  return (
    <div className="App">
      <header className="App-header">
        <h1>🚀 Wander Dev Environment</h1>
        <p>Your development environment is up and running!</p>

        <div className="status-card">
          <h2>API Status</h2>
          {loading && <p>Loading...</p>}
          {error && <p className="error">❌ Error: {error}</p>}
          {apiStatus && (
            <div className="status-details">
              <p>✅ Connected to API</p>
              <p><strong>Message:</strong> {apiStatus.message}</p>
              <p><strong>Version:</strong> {apiStatus.version}</p>
              <p><strong>Environment:</strong> {apiStatus.environment}</p>
            </div>
          )}
        </div>

        <div className="links">
          <a href={`${API_URL}/health`} target="_blank" rel="noopener noreferrer">
            API Health Check
          </a>
          <a href={`${API_URL}/api/status`} target="_blank" rel="noopener noreferrer">
            API Status
          </a>
        </div>
      </header>
    </div>
  )
}

export default App
