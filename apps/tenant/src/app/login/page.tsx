'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/contexts/AuthContext'
import toast from 'react-hot-toast'

export default function LoginPage() {
  const { login }             = useAuth()
  const router                = useRouter()
  const [email, setEmail]     = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    try {
      await login(email, password)
      router.push('/dashboard')
    } catch {
      toast.error('Email ou mot de passe incorrect')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex">
      {/* Panel gauche — branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-clark-400 flex-col justify-between p-12">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 bg-white/20 rounded-xl flex items-center justify-center">
            <span className="text-white font-bold text-lg">C</span>
          </div>
          <span className="text-white font-semibold text-xl tracking-tight">Clark</span>
        </div>

        <div>
          <h1 className="text-4xl font-bold text-white leading-tight mb-4">
            Votre logement,<br />simplement.
          </h1>
          <p className="text-clark-100 text-lg leading-relaxed">
            Accédez à vos documents, signalez un incident ou
            discutez avec Clark — votre assistant disponible 24h/24.
          </p>
        </div>

        <div className="flex flex-col gap-3">
          {[
            { icon: '📄', label: 'Bail & quittances en un clic' },
            { icon: '🔧', label: 'Signalement d\'incident instantané' },
            { icon: '💬', label: 'Assistant disponible 24h/24' },
          ].map((item) => (
            <div key={item.label} className="flex items-center gap-3">
              <span className="text-xl">{item.icon}</span>
              <span className="text-clark-100 text-sm">{item.label}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Panel droit — formulaire */}
      <div className="flex-1 flex items-center justify-center p-8 bg-[--clark-bg]">
        <div className="w-full max-w-sm">
          {/* Logo mobile */}
          <div className="lg:hidden flex items-center gap-3 mb-10">
            <div className="w-9 h-9 bg-clark-400 rounded-xl flex items-center justify-center">
              <span className="text-white font-bold text-lg">C</span>
            </div>
            <span className="text-[--clark-text] font-semibold text-xl tracking-tight">Clark</span>
          </div>

          <h2 className="text-2xl font-bold text-[--clark-text] mb-1">Bon retour 👋</h2>
          <p className="text-[--clark-muted] text-sm mb-8">Connectez-vous à votre espace locataire</p>

          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div>
              <label className="block text-sm font-medium text-[--clark-text] mb-1.5">
                Email
              </label>
              <input
                type="email"
                className="input"
                placeholder="alice@exemple.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
              />
            </div>

            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="text-sm font-medium text-[--clark-text]">Mot de passe</label>
                <a href="/forgot-password" className="text-xs text-clark-400 hover:text-clark-500">
                  Mot de passe oublié ?
                </a>
              </div>
              <input
                type="password"
                className="input"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                autoComplete="current-password"
              />
            </div>

            <button
              type="submit"
              className="btn-primary w-full mt-2"
              disabled={loading}
            >
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

          <p className="text-center text-xs text-[--clark-muted] mt-8">
            Un problème ?{' '}
            <a href="mailto:support@clarkrent.com" className="text-clark-400 hover:underline">
              Contactez le support
            </a>
          </p>
        </div>
      </div>
    </div>
  )
}
