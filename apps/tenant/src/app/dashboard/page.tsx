'use client'

import { useEffect, useState } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import api from '@/lib/api'
import Link from 'next/link'
import {
  Home, FileText, Wrench, MessageCircle,
  ChevronRight, AlertCircle, CheckCircle2, Clock
} from 'lucide-react'
import { format } from 'date-fns'
import { fr } from 'date-fns/locale'

interface LeaseContext {
  address: string
  rent: number
  expenses: number
  lease_status: string
}

interface Ticket {
  id: number
  category: string
  status: string
  priority: string
  created_at: string
}

interface Payment {
  month: string
  amount: number
  status: string
  paid_at: string | null
}

export default function DashboardPage() {
  const { user } = useAuth()
  const [ctx, setCtx]           = useState<LeaseContext | null>(null)
  const [tickets, setTickets]   = useState<Ticket[]>([])
  const [payments, setPayments] = useState<Payment[]>([])
  const [loading, setLoading]   = useState(true)

  useEffect(() => {
    Promise.all([
      api.get('/agent/context'),
      api.get('/agent/tickets'),
      api.get('/agent/payments'),
    ]).then(([ctxRes, ticketRes, payRes]) => {
      setCtx(ctxRes.data)
      setTickets(ticketRes.data.tickets?.slice(0, 3) || [])
      setPayments(payRes.data.payments?.slice(0, 3) || [])
    }).finally(() => setLoading(false))
  }, [])

  const nextDue = new Date()
  nextDue.setDate(1)
  nextDue.setMonth(nextDue.getMonth() + 1)

  const statusBadge = (status: string, priority?: string) => {
    if (priority === 'urgent') return <span className="badge-red">🚨 Urgent</span>
    if (status === 'open')     return <span className="badge-orange">En cours</span>
    if (status === 'resolved') return <span className="badge-green">Résolu</span>
    return <span className="badge-gray">{status}</span>
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-clark-400 border-t-transparent rounded-full animate-spin"/>
          <span className="text-sm text-[--clark-muted]">Chargement…</span>
        </div>
      </div>
    )
  }

  return (
    <div className="max-w-2xl mx-auto px-4 py-6 space-y-5">

      {/* Salutation */}
      <div>
        <h1 className="text-xl font-bold text-[--clark-text]">
          Bonjour, {user?.first_name} 👋
        </h1>
        <p className="text-sm text-[--clark-muted] mt-0.5">
          {format(new Date(), "EEEE d MMMM yyyy", { locale: fr })}
        </p>
      </div>

      {/* Card bail */}
      {ctx && (
        <div className="card bg-clark-400 border-0">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-clark-100 text-xs font-medium uppercase tracking-wide mb-1">
                Mon logement
              </p>
              <p className="text-white font-semibold text-base leading-snug">
                {ctx.address}
              </p>
            </div>
            <span className="badge-green bg-white/20 text-white text-xs px-2.5 py-1 rounded-full">
              Bail actif
            </span>
          </div>
          <div className="mt-4 pt-4 border-t border-white/20 flex gap-6">
            <div>
              <p className="text-clark-100 text-xs">Loyer</p>
              <p className="text-white font-semibold">{ctx.rent}€</p>
            </div>
            <div>
              <p className="text-clark-100 text-xs">Charges</p>
              <p className="text-white font-semibold">{ctx.expenses}€</p>
            </div>
            <div>
              <p className="text-clark-100 text-xs">Total</p>
              <p className="text-white font-semibold">{Number(ctx.rent) + Number(ctx.expenses)}€</p>
            </div>
          </div>
        </div>
      )}

      {/* Prochain loyer */}
      <div className="card flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-clark-50 rounded-xl flex items-center justify-center">
            <Clock className="w-5 h-5 text-clark-400" />
          </div>
          <div>
            <p className="text-xs text-[--clark-muted]">Prochain loyer</p>
            <p className="text-sm font-semibold text-[--clark-text]">
              {format(nextDue, "1 MMMM yyyy", { locale: fr })}
            </p>
          </div>
        </div>
        <span className="text-clark-400 font-bold">
          {ctx ? Number(ctx.rent) + Number(ctx.expenses) : '—'}€
        </span>
      </div>

      {/* Raccourcis rapides */}
      <div className="grid grid-cols-2 gap-3">
        {[
          { href: '/chat',      icon: MessageCircle, label: 'Parler à Clark',    color: 'bg-clark-50 text-clark-400' },
          { href: '/documents', icon: FileText,      label: 'Mes documents',     color: 'bg-purple-50 text-purple-500' },
          { href: '/incidents', icon: Wrench,        label: 'Signaler',          color: 'bg-orange-50 text-orange-500' },
          { href: '/lease',     icon: Home,          label: 'Mon bail',          color: 'bg-blue-50 text-blue-500' },
        ].map(({ href, icon: Icon, label, color }) => (
          <Link key={href} href={href}
            className="card-hover flex items-center gap-3 !p-4"
          >
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${color}`}>
              <Icon className="w-5 h-5" />
            </div>
            <span className="text-sm font-medium text-[--clark-text]">{label}</span>
          </Link>
        ))}
      </div>

      {/* Tickets récents */}
      {tickets.length > 0 && (
        <div>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-sm font-semibold text-[--clark-text]">Incidents en cours</h2>
            <Link href="/incidents" className="text-xs text-clark-400 hover:underline flex items-center gap-1">
              Voir tout <ChevronRight className="w-3 h-3" />
            </Link>
          </div>
          <div className="flex flex-col gap-2">
            {tickets.map((t) => (
              <div key={t.id} className="card !p-4 flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium capitalize text-[--clark-text]">{t.category}</p>
                  <p className="text-xs text-[--clark-muted] mt-0.5">#{t.id} · {t.created_at}</p>
                </div>
                {statusBadge(t.status, t.priority)}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* CTA Clark agent */}
      <Link href="/chat"
        className="card-hover !p-5 flex items-center gap-4 bg-gradient-to-r from-clark-50 to-white border-clark-200"
      >
        <div className="w-12 h-12 bg-clark-400 rounded-2xl flex items-center justify-center flex-shrink-0">
          <MessageCircle className="w-6 h-6 text-white" />
        </div>
        <div className="flex-1">
          <p className="font-semibold text-[--clark-text] text-sm">Parler à Clark</p>
          <p className="text-xs text-[--clark-muted] mt-0.5">
            Questions sur votre bail, signalement, documents — je suis là 24h/24.
          </p>
        </div>
        <ChevronRight className="w-5 h-5 text-[--clark-muted]" />
      </Link>

    </div>
  )
}
