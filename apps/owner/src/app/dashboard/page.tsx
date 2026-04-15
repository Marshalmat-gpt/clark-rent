'use client'

import { useEffect, useState } from 'react'
import api from '@/lib/api'
import { useAuth } from '@/contexts/AuthContext'
import Link from 'next/link'
import {
  Home, TrendingUp, AlertTriangle, Clock,
  ChevronRight, ArrowUpRight, Users, Wrench
} from 'lucide-react'
import {
  AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer
} from 'recharts'

interface Property {
  id: number
  address: string
  city: string
  lease_status: string
  rent: number
  tenant: string | null
  open_tickets: number
  alerts: string[]
}

interface OwnerCtx {
  name: string
  property_count: number
  open_leases: number
  open_tickets: number
}

// Données synthétiques revenus (à remplacer par API)
const REVENUE_DATA = [
  { month: 'Oct', amount: 1670 },
  { month: 'Nov', amount: 1670 },
  { month: 'Déc', amount: 1670 },
  { month: 'Jan', amount: 1670 },
  { month: 'Fév', amount: 1670 },
  { month: 'Mar', amount: 1670 },
  { month: 'Avr', amount: 1670 },
]

export default function DashboardPage() {
  const { user }                  = useAuth()
  const [ctx, setCtx]             = useState<OwnerCtx | null>(null)
  const [properties, setProperties] = useState<Property[]>([])
  const [loading, setLoading]     = useState(true)

  useEffect(() => {
    Promise.all([
      api.get('/agent/context'),
      api.get('/agent/properties/summary'),
    ]).then(([ctxRes, propsRes]) => {
      setCtx(ctxRes.data)
      setProperties(propsRes.data.properties || [])
    }).finally(() => setLoading(false))
  }, [])

  const totalRent   = properties.reduce((s, p) => s + (p.rent || 0), 0)
  const alertCount  = properties.filter((p) => p.alerts?.length > 0).length
  const urgentTickets = properties.reduce((s, p) => s + p.open_tickets, 0)

  const STATS = [
    { label: 'Biens gérés',       value: ctx?.property_count ?? '—',  icon: Home,          color: 'bg-clark-50 text-clark-400' },
    { label: 'Revenus mensuels',  value: totalRent ? `${totalRent}€` : '—', icon: TrendingUp, color: 'bg-emerald-50 text-emerald-500' },
    { label: 'Tickets ouverts',   value: ctx?.open_tickets ?? '—',    icon: Wrench,        color: urgentTickets > 0 ? 'bg-orange-50 text-orange-500' : 'bg-clark-50 text-clark-400' },
    { label: 'Alertes',           value: alertCount,                  icon: AlertTriangle, color: alertCount > 0 ? 'bg-red-50 text-red-500' : 'bg-clark-50 text-clark-400' },
  ]

  return (
    <div className="space-y-6">

      {/* En-tête */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-[--text]">
            Bonjour, {user?.first_name} 👋
          </h1>
          <p className="text-sm text-[--muted] mt-0.5">Voici l'état de votre parc aujourd'hui</p>
        </div>
        <Link href="/properties/new" className="btn-primary">
          + Ajouter un bien
        </Link>
      </div>

      {/* Stats cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {STATS.map(({ label, value, icon: Icon, color }) => (
          <div key={label} className="stat-card">
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${color}`}>
              <Icon className="w-5 h-5" />
            </div>
            <p className="text-2xl font-bold text-[--text] mt-2">{value}</p>
            <p className="text-xs text-[--muted]">{label}</p>
          </div>
        ))}
      </div>

      {/* Graph revenus */}
      <div className="card">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-semibold text-[--text]">Revenus locatifs</h2>
          <span className="badge-green">+0% vs mois dernier</span>
        </div>
        <ResponsiveContainer width="100%" height={180}>
          <AreaChart data={REVENUE_DATA} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
            <defs>
              <linearGradient id="clarkGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%"  stopColor="#449A84" stopOpacity={0.15} />
                <stop offset="95%" stopColor="#449A84" stopOpacity={0} />
              </linearGradient>
            </defs>
            <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#6B7A76' }} axisLine={false} tickLine={false} />
            <YAxis tick={{ fontSize: 12, fill: '#6B7A76' }} axisLine={false} tickLine={false} />
            <Tooltip
              contentStyle={{ borderRadius: '12px', border: '1px solid #E2ECEA', fontSize: 13 }}
              formatter={(v: number) => [`${v}€`, 'Revenus']}
            />
            <Area type="monotone" dataKey="amount" stroke="#449A84" strokeWidth={2}
              fill="url(#clarkGradient)" dot={false} activeDot={{ r: 4, fill: '#449A84' }} />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* Liste biens */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="font-semibold text-[--text]">Mes biens</h2>
          <Link href="/properties" className="text-xs text-clark-400 hover:underline flex items-center gap-1">
            Voir tout <ChevronRight className="w-3 h-3" />
          </Link>
        </div>

        {loading ? (
          <div className="card flex items-center justify-center h-32">
            <div className="w-6 h-6 border-2 border-clark-400 border-t-transparent rounded-full animate-spin" />
          </div>
        ) : properties.length === 0 ? (
          <div className="card text-center py-10">
            <Home className="w-8 h-8 text-clark-200 mx-auto mb-2" />
            <p className="text-sm font-medium text-[--text]">Aucun bien enregistré</p>
            <Link href="/properties/new" className="btn-primary mt-4 mx-auto">Ajouter un bien</Link>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {properties.slice(0, 5).map((p) => (
              <Link key={p.id} href={`/properties/${p.id}`} className="card-hover !p-4 block">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-clark-50 rounded-xl flex items-center justify-center flex-shrink-0">
                      <Home className="w-5 h-5 text-clark-400" />
                    </div>
                    <div>
                      <p className="text-sm font-semibold text-[--text] leading-snug">{p.address}</p>
                      <p className="text-xs text-[--muted]">
                        {p.tenant ?? 'Vacant'} · {p.rent ? `${p.rent}€/mois` : '—'}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {p.alerts?.length > 0 && (
                      <span className="badge-orange">{p.alerts.length} alerte{p.alerts.length > 1 ? 's' : ''}</span>
                    )}
                    {p.open_tickets > 0 && (
                      <span className="badge-red">{p.open_tickets} ticket{p.open_tickets > 1 ? 's' : ''}</span>
                    )}
                    {!p.alerts?.length && !p.open_tickets && (
                      <span className="badge-green">OK</span>
                    )}
                    <ArrowUpRight className="w-4 h-4 text-[--muted]" />
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>

    </div>
  )
}
