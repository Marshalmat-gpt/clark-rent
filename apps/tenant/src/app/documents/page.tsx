'use client'

import { useEffect, useState } from 'react'
import api from '@/lib/api'
import { FileText, Download, Receipt, Home, ClipboardCheck } from 'lucide-react'
import toast from 'react-hot-toast'

const DOC_TYPES = [
  { type: 'lease',                 icon: Home,           label: 'Contrat de bail',           desc: 'Votre bail en cours' },
  { type: 'residence_certificate', icon: FileText,       label: 'Attestation de résidence',  desc: 'Pour vos démarches administratives' },
  { type: 'inventory',             icon: ClipboardCheck, label: 'État des lieux',             desc: 'État des lieux d\'entrée' },
  { type: 'receipt',               icon: Receipt,        label: 'Dernière quittance',         desc: 'Quittance du mois en cours' },
]

export default function DocumentsPage() {
  const [loading, setLoading] = useState<string | null>(null)
  const currentMonth          = new Date().toISOString().slice(0, 7) // YYYY-MM

  const handleDownload = async (type: string) => {
    setLoading(type)
    try {
      const params: any = { type }
      if (type === 'receipt') params.month = currentMonth

      const { data } = await api.get(`/agent/documents/${type}`, { params })

      // Ouvrir le lien S3 signé
      window.open(data.url, '_blank')
      toast.success('Document prêt au téléchargement')
    } catch {
      toast.error('Document indisponible pour le moment')
    } finally {
      setLoading(null)
    }
  }

  return (
    <div className="max-w-2xl mx-auto px-4 py-6">

      <h1 className="text-xl font-bold text-[--clark-text] mb-1">Mes documents</h1>
      <p className="text-sm text-[--clark-muted] mb-6">
        Tous vos documents disponibles en téléchargement sécurisé.
      </p>

      <div className="flex flex-col gap-3">
        {DOC_TYPES.map(({ type, icon: Icon, label, desc }) => (
          <button
            key={type}
            onClick={() => handleDownload(type)}
            disabled={loading === type}
            className="card-hover flex items-center gap-4 text-left w-full disabled:opacity-60 disabled:cursor-wait"
          >
            <div className="w-11 h-11 bg-clark-50 rounded-xl flex items-center justify-center flex-shrink-0">
              <Icon className="w-5 h-5 text-clark-400" />
            </div>
            <div className="flex-1">
              <p className="text-sm font-semibold text-[--clark-text]">{label}</p>
              <p className="text-xs text-[--clark-muted] mt-0.5">{desc}</p>
            </div>
            {loading === type ? (
              <div className="w-5 h-5 border-2 border-clark-400 border-t-transparent rounded-full animate-spin flex-shrink-0" />
            ) : (
              <Download className="w-5 h-5 text-[--clark-muted] flex-shrink-0" />
            )}
          </button>
        ))}
      </div>

      <p className="text-xs text-[--clark-muted] text-center mt-8">
        Les liens de téléchargement sont sécurisés et expirent après 1 heure.
        <br/>Pour toute demande spécifique, utilisez{' '}
        <a href="/chat" className="text-clark-400 hover:underline">l'assistant Clark</a>.
      </p>

    </div>
  )
}
