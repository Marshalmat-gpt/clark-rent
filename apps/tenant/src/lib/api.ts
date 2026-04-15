import axios from 'axios'
import Cookies from 'js-cookie'

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1',
  headers: { 'Content-Type': 'application/json' },
})

// Injecte le JWT automatiquement sur chaque requête
api.interceptors.request.use((config) => {
  const token = Cookies.get('clark_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// Redirige vers /login si 401
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401 && typeof window !== 'undefined') {
      Cookies.remove('clark_token')
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)

export default api
