'use client'

import { useState } from 'react'
import { Send, CheckCircle2 } from 'lucide-react'

export default function CTA() {
  const [form, setForm]       = useState({ name: '', email: '', message: '', type: 'owner' })
  const [submitted, setSubmitted] = useState(false)
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    // Simulé — à connecter à un endpoint Rails ou service email
    await new Promise((r) => setTimeout(r, 1200))
    setSubmitted(true)
    setLoading(false)
  }

  return (
    <section id="contact" className="section bg-clark-800">
      <div className="container">
        <div className="max-w-2xl mx-auto">

          <div className="text-center mb-12">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-white/10 border border-white/20 rounded-full text-clark-200 text-xs font-semibold uppercase tracking-wide mb-4">
              Contact
            </span>
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
              Prêt à déléguer votre gestion ?
            </h2>
            <p className="text-clark-200 text-lg">
              Laissez-nous vos coordonnées — un membre de l'équipe Clark vous rappelle sous 24h.
            </p>
          </div>

          {submitted ? (
            <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-3xl p-10 text-center">
              <CheckCircle2 className="w-12 h-12 text-clark-300 mx-auto mb-4" />
              <h3 className="text-xl font-bold text-white mb-2">Message reçu !</h3>
              <p className="text-clark-200">
                Nous vous recontactons sous 24h. À très bientôt 🙂
              </p>
            </div>
          ) : (
            <form onSubmit={handleSubmit}
              className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-3xl p-8 space-y-5"
            >
              {/* Profil */}
              <div className="flex gap-3">
                {[
                  { value: 'owner',  label: '🏡 Propriétaire' },
                  { value: 'tenant', label: '🔑 Locataire' },
                ].map(({ value, label }) => (
                  <button
                    key={value}
                    type="button"
                    onClick={() => setForm({ ...form, type: value })}
                    className={`flex-1 py-2.5 rounded-xl text-sm font-semibold border transition-all ${
                      form.type === value
                        ? 'bg-clark-400 text-white border-clark-400'
                        : 'bg-white/10 text-clark-200 border-white/20 hover:bg-white/20'
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </div>

              <div className="grid sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-clark-200 text-sm font-medium block mb-1.5">Nom Prénom</label>
                  <input
                    type="text"
                    className="w-full px-4 py-2.5 bg-white/10 border border-white/20 rounded-xl text-white
                               placeholder:text-clark-400 text-sm focus:outline-none focus:border-clark-300"
                    placeholder="Thomas Dupont"
                    value={form.name}
                    onChange={(e) => setForm({ ...form, name: e.target.value })}
                    required
                  />
                </div>
                <div>
                  <label className="text-clark-200 text-sm font-medium block mb-1.5">Email</label>
                  <input
                    type="email"
                    className="w-full px-4 py-2.5 bg-white/10 border border-white/20 rounded-xl text-white
                               placeholder:text-clark-400 text-sm focus:outline-none focus:border-clark-300"
                    placeholder="thomas@exemple.com"
                    value={form.email}
                    onChange={(e) => setForm({ ...form, email: e.target.value })}
                    required
                  />
                </div>
              </div>

              <div>
                <label className="text-clark-200 text-sm font-medium block mb-1.5">
                  Message <span className="text-clark-400">(facultatif)</span>
                </label>
                <textarea
                  className="w-full px-4 py-2.5 bg-white/10 border border-white/20 rounded-xl text-white
                             placeholder:text-clark-400 text-sm focus:outline-none focus:border-clark-300
                             resize-none min-h-[90px]"
                  placeholder="Décrivez votre situation (nombre de biens, ville, besoin spécifique…)"
                  value={form.message}
                  onChange={(e) => setForm({ ...form, message: e.target.value })}
                />
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full py-3.5 bg-clark-400 hover:bg-clark-300 text-white font-semibold
                           rounded-2xl transition-all flex items-center justify-center gap-2
                           disabled:opacity-60 disabled:cursor-not-allowed"
              >
                {loading ? (
                  <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
                  </svg>
                ) : (
                  <>Nous contacter <Send className="w-4 h-4" /></>
                )}
              </button>
            </form>
          )}
        </div>
      </div>
    </section>
  )
}
