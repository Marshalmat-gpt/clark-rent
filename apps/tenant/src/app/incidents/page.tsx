'use client'

import { useEffect, useState } from 'react'
import api from '@/lib/api'
import { Wrench, Plus, ChevronDown, ChevronUp } from 'lucide-react'
import toast from 'react-hot-toast'

interface Ticket {
  id: number
  category: string
  description: string
  status: string
  priority: string
  created_at: string
  assigned_to: string | null
  resolved_at: string | null
}

const CATEGORIES = [
  { value: 'plomberie',   label: '🚿 Plomberie' },
  { value: 'electricite', label: '⚡ Électricité' },
  { value: 'chauffage',   label: '🔥 Chauffage' },
  { value: 'serrurerie',  label: '🔑 Serrurerie' },
  { value: 'autre',       label: '🔧 Autre' },
]

const STATUS_LABELS: Record<string, string> = {
  open:     'Ouvert',
  assigned: 'Pris en charge',
  resolved: 'Résolu',
  closed:   'Fermé',
}

export default function IncidentsPage() {
  const [tickets, setTickets]         = useState<Ticket[]>([])
  const [loading, setLoading]         = useState(true)
  const [showForm, setShowForm]       = useState(false)
  const [expanded, setExpanded]       = useState<number | null>(null)
  const [submitting, setSubmitting]   = useState(false)
  const [form, setForm]               = useState({
    category: 'plomberie',
    description: '',
    priority: 'normal',
  })

  const fetchTickets = () => {
    api.get('/agent/tickets')
      .then((r) => setTickets(r.data.tickets || []))
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchTickets() }, [])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!form.description.trim()) return
    setSubmitting(true)
    try {
      await api.post('/agent/tickets', form)
      toast.success('Incident signalé — votre propriétaire a été notifié.')
      setShowForm(false)
      setForm({ category: 'plomberie', description: '', priority: 'normal' })
      fetchTickets()
    } catch {
      toast.error('Erreur lors de l\'envoi. Réessayez.')
    } finally {
      setSubmitting(false)
    }
  }

  const badgeClass = (status: string, priority: string) => {
    if (priority === 'urgent') return 'badge-red'
    if (status === 'resolved' || status === 'closed') return 'badge-green'
    if (status === 'assigned') return 'badge-orange'
    return 'badge-orange'
  }

  return (
    <div className="max-w-2xl mx-auto px-4 py-6">

      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-xl font-bold text-[--clark-text]">Mes incidents</h1>
          <p className="text-sm text-[--clark-muted] mt-0.5">Signalez un problème ou suivez vos demandes</p>
        </div>
        <button
          onClick={() => setShowForm(!showForm)}
          className="btn-primary"
        >
          <Plus className="w-4 h-4" />
          Signaler
        </button>
      </div>

      {/* Formulaire de signalement */}
      {showForm && (
        <form onSubmit={handleSubmit} className="card mb-5 space-y-4">
          <h2 className="font-semibold text-[--clark-text]">Nouveau signalement</h2>

          <div>
            <label className="text-sm font-medium text-[--clark-text] block mb-1.5">
              Catégorie
            </label>
            <select
              className="input"
              value={form.category}
              onChange={(e) => setForm({ ...form, category: e.target.value })}
            >
              {CATEGORIES.map((c) => (
                <option key={c.value} value={c.value}>{c.label}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="text-sm font-medium text-[--clark-text] block mb-1.5">
              Description
            </label>
            <textarea
              className="input min-h-[90px] resize-none"
              placeholder="Décrivez le problème en quelques mots…"
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              required
            />
          </div>

          <div className="flex items-center gap-3">
            <label className="text-sm font-medium text-[--clark-text]">Priorité</label>
            <div className="flex gap-2">
              {(['normal', 'urgent'] as const).map((p) => (
                <button
                  key={p}
                  type="button"
                  onClick={() => setForm({ ...form, priority: p })}
                  className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition-colors ${
                    form.priority === p
                      ? p === 'urgent'
                        ? 'bg-red-500 text-white border-red-500'
                        : 'bg-clark-400 text-white border-clark-400'
                      : 'bg-white text-[--clark-muted] border-[--clark-border] hover:border-clark-300'
                  }`}
                >
                  {p === 'urgent' ? '🚨 Urgent' : 'Normal'}
                </button>
              ))}
            </div>
          </div>

          <div className="flex gap-2 pt-1">
            <button
              type="button"
              onClick={() => setShowForm(false)}
              className="btn-ghost flex-1"
            >
              Annuler
            </button>
            <button
              type="submit"
              className="btn-primary flex-1"
              disabled={submitting}
            >
              {submitting ? 'Envoi…' : 'Envoyer le signalement'}
            </button>
          </div>
        </form>
      )}

      {/* Liste des tickets */}
      {loading ? (
        <div className="flex justify-center py-12">
          <div className="w-7 h-7 border-2 border-clark-400 border-t-transparent rounded-full animate-spin" />
        </div>
      ) : tickets.length === 0 ? (
        <div className="text-center py-16">
          <div className="w-14 h-14 bg-clark-50 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <Wrench className="w-7 h-7 text-clark-400" />
          </div>
          <p className="text-[--clark-text] font-medium">Aucun incident signalé</p>
          <p className="text-sm text-[--clark-muted] mt-1">Tout se passe bien dans votre logement 🎉</p>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          {tickets.map((t) => (
            <div key={t.id} className="card">
              <button
                className="w-full flex items-center gap-3 text-left"
                onClick={() => setExpanded(expanded === t.id ? null : t.id)}
              >
                <div className="w-10 h-10 bg-gray-50 rounded-xl flex items-center justify-center flex-shrink-0 text-lg">
                  {CATEGORIES.find((c) => c.value === t.category)?.label.split(' ')[0] ?? '🔧'}
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-semibold text-[--clark-text] capitalize">{t.category}</p>
                    <span className={badgeClass(t.status, t.priority)}>
                      {t.priority === 'urgent' ? 'Urgent' : STATUS_LABELS[t.status] || t.status}
                    </span>
                  </div>
                  <p className="text-xs text-[--clark-muted] mt-0.5">#{t.id} · {t.created_at}</p>
                </div>
                {expanded === t.id
                  ? <ChevronUp className="w-4 h-4 text-[--clark-muted]" />
                  : <ChevronDown className="w-4 h-4 text-[--clark-muted]" />
                }
              </button>

              {expanded === t.id && (
                <div className="mt-3 pt-3 border-t border-[--clark-border] space-y-2">
                  <p className="text-sm text-[--clark-text] leading-relaxed">{t.description}</p>
                  {t.assigned_to && (
                    <p className="text-xs text-[--clark-muted]">
                      Intervenant assigné : <span className="font-medium">{t.assigned_to}</span>
                    </p>
                  )}
                  {t.resolved_at && (
                    <p className="text-xs text-clark-400">✓ Résolu le {t.resolved_at}</p>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}

    </div>
  )
}
