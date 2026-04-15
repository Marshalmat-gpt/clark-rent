'use client'

import { useEffect, useState } from 'react'
import { useSearchParams } from 'next/navigation'
import api from '@/lib/api'
import toast from 'react-hot-toast'
import { Users, CheckCircle2, XCircle, Clock, ChevronDown, ChevronUp } from 'lucide-react'

interface Application {
  id: number
  status: string
  applicant: string
  email: string
  description: string
  submitted_at: string
}

const STATUS_LABELS: Record<string, string> = {
  new:                'Nouvelle',
  inprogress:         'En cours',
  approved:           'Approuvée',
  rejected_by_owner:  'Refusée',
  rejected_by_staff:  'Refusée (Clark)',
}

export default function ApplicationsPage() {
  const searchParams          = useSearchParams()
  const leaseId               = searchParams.get('lease')
  const [apps, setApps]       = useState<Application[]>([])
  const [loading, setLoading] = useState(true)
  const [expanded, setExpanded] = useState<number | null>(null)
  const [acting, setActing]   = useState<number | null>(null)

  const fetchApps = () => {
    if (!leaseId) return setLoading(false)
    api.get('/agent/applications', { params: { lease_id: leaseId } })
      .then((r) => setApps(r.data.applications || []))
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchApps() }, [leaseId])

  const handleDecision = async (appId: number, decision: 'approved' | 'rejected_by_owner') => {
    setActing(appId)
    try {
      await api.patch(`/lease_applications/${appId}`, { status: decision })
      toast.success(decision === 'approved' ? 'Candidature approuvée ✓' : 'Candidature refusée')
      fetchApps()
    } catch {
      toast.error('Erreur lors de la mise à jour')
    } finally {
      setActing(null)
    }
  }

  const pending  = apps.filter((a) => ['new', 'inprogress'].includes(a.status))
  const decided  = apps.filter((a) => !['new', 'inprogress'].includes(a.status))

  return (
    <div className="space-y-5 max-w-2xl">

      <div>
        <h1 className="text-xl font-bold text-[--text]">Candidatures</h1>
        <p className="text-sm text-[--muted] mt-0.5">
          {apps.length} candidature{apps.length > 1 ? 's' : ''} · {pending.length} en attente
        </p>
      </div>

      {loading ? (
        <div className="card flex items-center justify-center h-32">
          <div className="w-6 h-6 border-2 border-clark-400 border-t-transparent rounded-full animate-spin" />
        </div>
      ) : apps.length === 0 ? (
        <div className="card text-center py-12">
          <Users className="w-8 h-8 text-clark-200 mx-auto mb-3" />
          <p className="text-sm font-medium text-[--text]">Aucune candidature reçue</p>
          <p className="text-xs text-[--muted] mt-1">Partagez l'annonce pour recevoir des dossiers</p>
        </div>
      ) : (
        <>
          {/* En attente */}
          {pending.length > 0 && (
            <div>
              <h2 className="text-sm font-semibold text-[--text] mb-2 flex items-center gap-2">
                <Clock className="w-4 h-4 text-orange-500" />
                En attente de décision ({pending.length})
              </h2>
              <div className="flex flex-col gap-3">
                {pending.map((a) => (
                  <div key={a.id} className="card space-y-3">
                    <button
                      className="w-full flex items-center justify-between"
                      onClick={() => setExpanded(expanded === a.id ? null : a.id)}
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 bg-clark-50 rounded-full flex items-center justify-center font-semibold text-clark-400 text-sm flex-shrink-0">
                          {a.applicant.charAt(0)}
                        </div>
                        <div className="text-left">
                          <p className="text-sm font-semibold text-[--text]">{a.applicant}</p>
                          <p className="text-xs text-[--muted]">{a.email} · {a.submitted_at}</p>
                        </div>
                      </div>
                      {expanded === a.id
                        ? <ChevronUp className="w-4 h-4 text-[--muted]" />
                        : <ChevronDown className="w-4 h-4 text-[--muted]" />
                      }
                    </button>

                    {expanded === a.id && (
                      <>
                        {a.description && (
                          <p className="text-sm text-[--text] bg-[--bg] rounded-xl p-3 leading-relaxed">
                            {a.description}
                          </p>
                        )}
                        <div className="flex gap-2">
                          <button
                            onClick={() => handleDecision(a.id, 'rejected_by_owner')}
                            disabled={acting === a.id}
                            className="btn-danger flex-1 justify-center"
                          >
                            <XCircle className="w-4 h-4" />
                            Refuser
                          </button>
                          <button
                            onClick={() => handleDecision(a.id, 'approved')}
                            disabled={acting === a.id}
                            className="btn-primary flex-1 justify-center"
                          >
                            <CheckCircle2 className="w-4 h-4" />
                            Approuver
                          </button>
                        </div>
                      </>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Traitées */}
          {decided.length > 0 && (
            <div>
              <h2 className="text-sm font-semibold text-[--muted] mb-2">
                Traitées ({decided.length})
              </h2>
              <div className="flex flex-col gap-2">
                {decided.map((a) => (
                  <div key={a.id} className="card !p-4 flex items-center justify-between opacity-70">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center font-medium text-gray-500 text-sm flex-shrink-0">
                        {a.applicant.charAt(0)}
                      </div>
                      <div>
                        <p className="text-sm font-medium text-[--text]">{a.applicant}</p>
                        <p className="text-xs text-[--muted]">{a.submitted_at}</p>
                      </div>
                    </div>
                    <span className={a.status === 'approved' ? 'badge-green' : 'badge-gray'}>
                      {STATUS_LABELS[a.status] ?? a.status}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </>
      )}
    </div>
  )
}
