'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/contexts/AuthContext'
import toast from 'react-hot-toast'
import { BarChart3, Users, Wrench, FileText } from 'lucide-react'

export default function LoginPage() {
  const { login }               = useAuth()
  const router                  = useRouter()
  const [email, setEmail]       = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading]   = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    try {
      await login(email, password)
      router.push('/dashboard')
    } catch {
      toast.error('Identifiants incorrects')
    } finally {
      setLoading(false)
    }
  }

  const FEATURES = [
    { icon: BarChart3, label: 'Vue d\'ensemble de votre parc en temps réel' },
    { icon: Users,     label: 'Gestion des candidatures et locataires' },
    { icon: Wrench,    label: 'Suivi des interventions et maintenance' },
    { icon: FileText,  label: 'Quittances, IRL et documents automatisés' },
  ]

  return (
    <div className="min-h-screen flex">
      {/* Sidebar branding */}
      <div className="hidden lg:flex lg:w-[420px] flex-col bg-[--dark] p-10 justify-between flex-shrink-0">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 bg-clark-400 rounded-xl flex items-center justify-center">
            <span className="text-white font-bold text-base">C</span>
          </div>
          <div>
            <span className="text-white font-semibold tracking-tight">Clark</span>
            <span className="text-clark-400 font-medium ml-1 text-sm">Pro</span>
          </div>
        </div>

        <div>
          <p className="text-clark-400 text-sm font-medium uppercase tracking-widest mb-4">
            Espace propriétaire
          </p>
          <h1 className="text-3xl font-bold text-white leading-snug mb-6">
            Pilotez votre parc<br />sans effort.
          </h1>
          <div className="flex flex-col gap-4">
            {FEATURES.map(({ icon: Icon, label }) => (
              <div key={label} className="flex items-start gap-3">
                <div className="w-8 h-8 bg-white/10 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5">
                  <Icon className="w-4 h-4 text-clark-400" />
                </div>
                <p className="text-gray-300 text-sm leading-relaxed">{label}</p>
              </div>
            ))}
          </div>
        </div>

        <p className="text-gray-600 text-xs">
          © {new Date().getFullYear()} Clark Rent — Gestion locative intelligente
        </p>
      </div>

      {/* Formulaire */}
      <div className="flex-1 flex items-center justify-center p-8 bg-[--bg]">
        <div className="w-full max-w-sm">
          {/* Logo mobile */}
          <div className="lg:hidden flex items-center gap-2 mb-10">
            <div className="w-8 h-8 bg-clark-400 rounded-xl flex items-center justify-center">
              <span className="text-white font-bold text-sm">C</span>
            </div>
            <span className="font-semibold text-[--text]">Clark <span className="text-clark-400">Pro</span></span>
          </div>

          <h2 className="text-2xl font-bold text-[--text] mb-1">Connexion</h2>
          <p className="text-sm text-[--muted] mb-8">Accédez à votre tableau de bord propriétaire</p>

          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div>
              <label className="text-sm font-medium text-[--text] block mb-1.5">Email</label>
              <input
                type="email" className="input"
                placeholder="thomas@clarkrent.com"
                value={email} onChange={(e) => setEmail(e.target.value)}
                required autoComplete="email"
              />
            </div>
            <div>
              <div className="flex justify-between mb-1.5">
                <label className="text-sm font-medium text-[--text]">Mot de passe</label>
                <a href="/forgot-password" className="text-xs text-clark-400 hover:underline">Oublié ?</a>
              </div>
              <input
                type="password" className="input"
                placeholder="••••••••"
                value={password} onChange={(e) => setPassword(e.target.value)}
                required autoComplete="current-password"
              />
            </div>

            <button type="submit" className="btn-primary w-full justify-center mt-2" disabled={loading}>
              {loading ? (
                <span className="flex items-center gap-2">
                  <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
                  </svg>
                  Connexion...
                </span>
              ) : 'Se connecter'}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}
