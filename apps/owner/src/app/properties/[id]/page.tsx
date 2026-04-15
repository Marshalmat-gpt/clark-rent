'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import api from '@/lib/api'
import Link from 'next/link'
import toast from 'react-hot-toast'
import {
  ArrowLeft, Home, User, Euro, Calendar,
  Wrench, TrendingUp, AlertTriangle, ChevronRight
} from 'lucide-react'

interface Property {
  id: number
  address: string
  surface: number
  type: string
  energy: string
  dpe_date: string
}

interface Lease {
  id: number
  status: string
  amount: number
  expense_amount: number
  tenant: string
  tenant_phone: string
  start_date: string
  end_date: string
  days_to_expiry: number
}

interface Ticket {
  id: number
  category: string
  status: string
  priority: string
  date: string
}

export default function PropertyDetailPage() {
  const params            = useParams()
  const router            = useRouter()
  const [property, setProperty] = useState<Property | null>(null)
  const [lease, setLease]       = useState<Lease | null>(null)
  const [tickets, setTickets]   = useState<Ticket[]>([])
  const [irl, setIrl]           = useState<any>(null)
  const [loading, setLoading]   = useState(true)
  const [generating, setGenerating] = useState(false)

  useEffect(() => {
    api.get(`/agent/properties/${params.id}`)
      .then((r) => {
        setProperty(r.data.property)
        setLease(r.data.lease)
        setTickets(r.data.recent_tickets || [])
        // Calculer IRL si bail actif
        if (r.data.lease?.id) {
          api.get(`/agent/leases/${r.data.lease.id}/irl`)
            .then((irl) => setIrl(irl.data))
            .catch(() => {})
        }
      })
      .finally(() => setLoading(false))
  }, [params.id])

  const generateReceipt = async () => {
    if (!lease) return
    setGenerating(true)
    try {
      const month = new Date().toISOString().slice(0, 7)
      const { data } = await api.post('/agent/receipts', { lease_id: lease.id, month })
      window.open(data.url, '_blank')
      toast.success('Quittance générée et envoyée au locataire')
    } catch {
      toast.error('Erreur lors de la génération')
    } finally {
      setGenerating(false)
    }
  }

  if (loading) return (
    <div className="flex items-center justify-center h-64">
      <div className="w-7 h-7 border-2 border-clark-400 border-t-transparent rounded-full animate-spin" />
    </div>
  )

  if (!property) return (
    <div className="text-center py-16">
      <p className="text-[--muted]">Bien introuvable</p>
      <Link href="/properties" className="btn-ghost mt-4">← Retour</Link>
    </div>
  )

  return (
    <div className="space-y-5 max-w-3xl">

      {/* Header */}
      <div className="flex items-center gap-3">
        <button onClick={() => router.back()} className="btn-ghost !px-2">
          <ArrowLeft className="w-4 h-4" />
        </button>
        <div>
          <h1 className="text-lg font-bold text-[--text] leading-snug">{property.address}</h1>
          <p className="text-xs text-[--muted]">
            {property.type} · {property.surface} m² · DPE {property.energy}
          </p>
        </div>
      </div>

      {/* Alerte expiration */}
      {lease?.days_to_expiry !== undefined && lease.days_to_expiry <= 60 && (
        <div className="flex items-start gap-3 p-4 bg-orange-50 border border-orange-200 rounded-2xl">
          <AlertTriangle className="w-5 h-5 text-orange-500 flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-semibold text-orange-700">
              Bail expirant dans {lease.days_to_expiry} jours
            </p>
            <p className="text-xs text-orange-600 mt-0.5">
              Pensez à envoyer le préavis de renouvellement au locataire.
            </p>
          </div>
        </div>
      )}

      {/* Bail actif */}
      {lease ? (
        <div className="card space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="font-semibold text-[--text]">Bail en cours</h2>
            <span className="badge-green">Actif</span>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="flex items-center gap-3">
              <User className="w-4 h-4 text-[--muted]" />
              <div>
                <p className="text-xs text-[--muted]">Locataire</p>
                <p className="text-sm font-medium">{lease.tenant}</p>
                {lease.tenant_phone && (
                  <p className="text-xs text-clark-400">{lease.tenant_phone}</p>
                )}
              </div>
            </div>
            <div className="flex items-center gap-3">
              <Euro className="w-4 h-4 text-[--muted]" />
              <div>
                <p className="text-xs text-[--muted]">Loyer + charges</p>
                <p className="text-sm font-medium">{lease.amount}€ + {lease.expense_amount}€</p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <Calendar className="w-4 h-4 text-[--muted]" />
              <div>
                <p className="text-xs text-[--muted]">Début — Fin</p>
                <p className="text-sm font-medium">{lease.start_date} → {lease.end_date ?? '∞'}</p>
              </div>
            </div>
          </div>

          <div className="flex gap-2 pt-2 border-t border-[--border]">
            <button
              onClick={generateReceipt}
              disabled={generating}
              className="btn-primary flex-1 justify-center"
            >
              {generating ? 'Génération…' : 'Générer la quittance'}
            </button>
            <Link href={`/applications?lease=${lease.id}`} className="btn-ghost flex-1 justify-center">
              Candidatures
            </Link>
          </div>
        </div>
      ) : (
        <div className="card text-center py-8">
          <Home className="w-8 h-8 text-clark-200 mx-auto mb-2" />
          <p className="text-sm font-medium text-[--text]">Aucun bail actif — bien vacant</p>
          <Link href={`/properties/${property.id}/new-lease`} className="btn-primary mt-4 mx-auto">
            Créer un bail
          </Link>
        </div>
      )}

      {/* Révision IRL */}
      {irl && (
        <div className="card">
          <div className="flex items-center gap-2 mb-3">
            <TrendingUp className="w-4 h-4 text-clark-400" />
            <h2 className="font-semibold text-[--text]">Révision IRL</h2>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div className="bg-[--bg] rounded-xl p-3 text-center">
              <p className="text-xs text-[--muted] mb-1">Loyer actuel</p>
              <p className="font-bold text-[--text]">{irl.current_rent}€</p>
            </div>
            <div className="bg-clark-50 rounded-xl p-3 text-center">
              <p className="text-xs text-clark-600 mb-1">Nouveau loyer</p>
              <p className="font-bold text-clark-500">{irl.new_rent}€</p>
            </div>
            <div className="bg-emerald-50 rounded-xl p-3 text-center">
              <p className="text-xs text-emerald-600 mb-1">Gain annuel</p>
              <p className="font-bold text-emerald-600">+{irl.annual_gain}€</p>
            </div>
          </div>
          <p className="text-xs text-[--muted] mt-3">
            IRL appliqué : {irl.irl_applied} · Date de révision : {irl.revision_date}
          </p>
        </div>
      )}

      {/* Tickets récents */}
      {tickets.length > 0 && (
        <div>
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-semibold text-[--text]">Interventions récentes</h2>
            <Link href={`/tickets?property=${property.id}`} className="text-xs text-clark-400 hover:underline flex items-center gap-1">
              Voir tout <ChevronRight className="w-3 h-3" />
            </Link>
          </div>
          <div className="flex flex-col gap-2">
            {tickets.map((t) => (
              <div key={t.id} className="card !p-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Wrench className="w-4 h-4 text-[--muted]" />
                  <div>
                    <p className="text-sm font-medium capitalize text-[--text]">{t.category}</p>
                    <p className="text-xs text-[--muted]">#{t.id} · {t.date}</p>
                  </div>
                </div>
                <span className={
                  t.priority === 'urgent' ? 'badge-red' :
                  t.status === 'resolved'  ? 'badge-green' : 'badge-orange'
                }>
                  {t.priority === 'urgent' ? 'Urgent' : t.status === 'resolved' ? 'Résolu' : 'En cours'}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

    </div>
  )
}
