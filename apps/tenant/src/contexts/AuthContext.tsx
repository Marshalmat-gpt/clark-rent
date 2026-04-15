'use client'

import React, { createContext, useContext, useEffect, useState } from 'react'
import Cookies from 'js-cookie'
import api from '@/lib/api'

interface User {
  id: number
  email: string
  first_name: string
  last_name: string
  role: string
}

interface AuthCtx {
  user: User | null
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
}

const AuthContext = createContext<AuthCtx | null>(null)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser]       = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  // Rehydrate depuis le cookie au démarrage
  useEffect(() => {
    const token = Cookies.get('clark_token')
    if (token) {
      api.get('/users/me')
        .then((r) => setUser(r.data))
        .catch(() => Cookies.remove('clark_token'))
        .finally(() => setLoading(false))
    } else {
      setLoading(false)
    }
  }, [])

  const login = async (email: string, password: string) => {
    const { data } = await api.post('/sessions', { email, password })
    Cookies.set('clark_token', data.token, { expires: 30, secure: true, sameSite: 'lax' })
    setUser(data.user)
  }

  const logout = () => {
    Cookies.remove('clark_token')
    setUser(null)
    window.location.href = '/login'
  }

  return (
    <AuthContext.Provider value={{ user, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider')
  return ctx
}
