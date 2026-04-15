'use client'

import { useEffect, useState } from 'react'
import api from '@/lib/api'
import { Wrench, AlertTriangle, CheckCircle2, Clock } from 'lucide-react'

interface Ticket {
  id: number
  property_address?: string
  category: string
  description: string
  status: string
  priority: string
  tenant: string
  created_at: string
  assigned_to: string | null
}

const CATEGORY_ICONS: Record<string, string> = {
  plomberie:   '🚿',
  electricite: '⚡',
  chauffage:   '🔥',
  serrurerie:  '🔑',
  autre:       '🔧',
}

export default function TicketsPage() {
  const [tickets, setTickets] = useState<Ticket[]>([])
  const [filter, setFilter]   = useState<'all' | 'open' | 'urgent' | 'resolved'>('all')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.get('/agent/tickets')
      .then((r) => setTickets(r.data.tickets || []))
      .finally(() => setLoading(false))
  }, [])

  const filtered = tickets.filter((t) => {
    if (filter === 'open')     return ['open', 'assigned'].includes(t.status)
    if (filter === 'urgent')   return t.priority === 'urgent'
    if (filter === 'resolved') return ['resolved', 'closed'].includes(t.status)
    return true
  })

  const urgentCount = tickets.filter((t) => t.priority === 'urgent' && t.status === 'open').length

  const FILTERS = [
    { key: 'all',      label: 'Tous',     count: tickets.length },
    { key: 'open',     label: 'Ouverts',  count: tickets.filter((t) => ['open','assigned'].includes(t.status)).length },
    { key: 'urgent',   label: '🚨 Urgents', count: urgentCount },
    { key: 'resolved', label: 'Résolus',  count: tickets.filter((t) => ['resolved','closed'].includes(t.status)).length },
  ]

  return (
    <div className="space-y-5 max-w-2xl">

      <div>
        <h1 className="text-xl font-bold text-[--text]">Interventions</h1>
        <p className="text-sm text-[--muted] mt-0.5">
          {tickets.length} ticket{tickets.length > 1 ? 's' : ''}
          {urgentCount > 0 && <span className="text-red-500 font-medium"> · {urgentCount} urgent{urgentCount > 1 ? 's' : ''}</span>}
        </p>
      </div>

      {/* Filtres */}
      <div className="flex gap-2 flex-wrap">
        {FILTERS.map(({ key, label, count }) => (
          <button
            key={key}
            onClick={() => setFilter(key as any)}
            className={`px-3 py-1.5 rounded-xl text-sm font-medium border transition-all ${
              filter === key
                ? 'bg-clark-400 text-white border-clark-400'
                : 'bg-white text-[--muted] border-[--border] hover:border-clark-300'
            }`}
          >
            {label} <span className="opacity-70">({count})</span>
          </button>
        ))}
      </div>

      {/* Liste */}
      {loading ? (
        <div className="card flex items-center justify-center h-32">
          <div className="w-6 h-6 border-2 border-clark-400 border-t-transparent rounded-full animate-spin" />
        </div>
      ) : filtered.length === 0 ? (
        <div className="card text-center py-12">
          <CheckCircle2 className="w-8 h-8 text-clark-300 mx-auto mb-3" />
          <p className="text-sm font-medium text-[--text]">Aucun ticket dans cette catégorie</p>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          {filtered.map((t) => (
            <div key={t.id} className="card !p-4 space-y-3">
              <div className="flex items-start justify-between gap-2">
                <div className="flex items-center gap-3">
                  <span className="text-xl flex-shrink-0">
                    {CATEGORY_ICONS[t.category] ?? '🔧'}
                  </span>
                  <div>
                    <div className="flex items-center gap-2 flex-wrap">
                      <p className="text-sm font-semibold capitalize text-[--text]">{t.category}</p>
                      {t.priority === 'urgent' && <span className="badge-red">Urgent</span>}
                    </div>
                    {t.property_address && (
                      <p className="text-xs text-clark-400 mt-0.5">{t.property_address}</p>
                    )}
                    <p className="text-xs text-[--muted]">
                      {t.tenant} · #{t.id} · {t.created_at}
                    </p>
                  </div>
                </div>
                <span className={
                  t.status === 'resolved' || t.status === 'closed' ? 'badge-green' :
                  t.status === 'assigned' ? 'badge-blue' : 'badge-orange'
                }>
                  {t.status === 'open' ? 'Ouvert' :
                   t.status === 'assigned' ? 'Assigné' :
                   t.status === 'resolved' ? 'Résolu' : 'Fermé'}
                </span>
              </div>

              <p className="text-sm text-[--text] leading-relaxed bg-[--bg] rounded-xl p-3">
                {t.description}
              </p>

              {t.assigned_to && (
                <p className="text-xs text-[--muted] flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  Intervenant : <span className="font-medium">{t.assigned_to}</span>
                </p>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
