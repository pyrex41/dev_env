import { useState, useEffect } from 'react'
import './App.css'

interface User {
  id: number
  email: string
  username: string
  created_at: string
}

interface Post {
  id: number
  title: string
  content: string
  status: string
  created_at: string
  username: string
  email: string
}

function App() {
  const [apiStatus, setApiStatus] = useState<any>(null)
  const [users, setUsers] = useState<User[]>([])
  const [posts, setPosts] = useState<Post[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<'status' | 'users' | 'posts'>('status')

  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

  useEffect(() => {
    const fetchData = async () => {
      try {
        // Fetch API status
        const statusResponse = await fetch(`${API_URL}/api/status`)
        if (!statusResponse.ok) throw new Error('Failed to fetch API status')
        const statusData = await statusResponse.json()
        setApiStatus(statusData)

        // Fetch users
        const usersResponse = await fetch(`${API_URL}/api/users`)
        if (!usersResponse.ok) throw new Error('Failed to fetch users')
        const usersData = await usersResponse.json()
        setUsers(usersData.users)

        // Fetch posts
        const postsResponse = await fetch(`${API_URL}/api/posts`)
        if (!postsResponse.ok) throw new Error('Failed to fetch posts')
        const postsData = await postsResponse.json()
        setPosts(postsData.posts)

        setError(null)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [API_URL])

  return (
    <div className="App">
      <header className="App-header">
        <h1 className="text-3xl font-bold text-blue-600">Wander Dev Environment</h1>
        <p>Your development environment is up and running!</p>

        {loading && <p>Loading data from database...</p>}
        {error && <p className="error">Error: {error}</p>}

        {!loading && !error && (
          <>
            <div className="tabs">
              <button
                className={activeTab === 'status' ? 'active' : ''}
                onClick={() => setActiveTab('status')}
              >
                API Status
              </button>
              <button
                className={activeTab === 'users' ? 'active' : ''}
                onClick={() => setActiveTab('users')}
              >
                Users ({users.length})
              </button>
              <button
                className={activeTab === 'posts' ? 'active' : ''}
                onClick={() => setActiveTab('posts')}
              >
                Posts ({posts.length})
              </button>
            </div>

            {activeTab === 'status' && (
              <div className="status-card">
                <h2>API Status</h2>
                <div className="status-details">
                  <p>Connected to API</p>
                  <p><strong>Message:</strong> {apiStatus.message}</p>
                  <p><strong>Version:</strong> {apiStatus.version}</p>
                  <p><strong>Environment:</strong> {apiStatus.environment}</p>
                </div>
                <div className="links">
                  <a href={`${API_URL}/health`} target="_blank" rel="noopener noreferrer">
                    API Health Check
                  </a>
                  <a href={`${API_URL}/api/status`} target="_blank" rel="noopener noreferrer">
                    API Status
                  </a>
                </div>
              </div>
            )}

            {activeTab === 'users' && (
              <div className="data-card">
                <h2>Users in Database</h2>
                <div className="data-grid">
                  {users.map((user) => (
                    <div key={user.id} className="data-item">
                      <h3>{user.username}</h3>
                      <p><strong>Email:</strong> {user.email}</p>
                      <p><strong>ID:</strong> {user.id}</p>
                      <p className="text-sm">
                        <strong>Created:</strong> {new Date(user.created_at).toLocaleDateString()}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {activeTab === 'posts' && (
              <div className="data-card">
                <h2>Published Posts</h2>
                <div className="data-list">
                  {posts.map((post) => (
                    <div key={post.id} className="post-item">
                      <h3>{post.title}</h3>
                      <p className="post-meta">
                        By <strong>{post.username}</strong> • {new Date(post.created_at).toLocaleDateString()}
                      </p>
                      <p className="post-content">{post.content}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </>
        )}
      </header>
    </div>
  )
}

export default App
