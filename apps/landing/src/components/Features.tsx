import { MessageCircle, FileText, Wrench, TrendingUp, Users, Bell, MapPin, Shield } from 'lucide-react'

const FEATURES = [
  {
    icon: MessageCircle,
    title: 'Assistant IA Clark',
    desc: 'Un agent conversationnel disponible 24h/24 pour répondre à toutes les questions des locataires et propriétaires en temps réel.',
    highlight: true,
  },
  {
    icon: FileText,
    title: 'Documents automatisés',
    desc: 'Quittances, baux, attestations de résidence — générés et envoyés automatiquement sans aucune action manuelle.',
  },
  {
    icon: Wrench,
    title: 'Gestion des incidents',
    desc: 'Signalement instantané, attribution à un intervenant local, suivi en temps réel jusqu\'à la résolution.',
  },
  {
    icon: TrendingUp,
    title: 'Révision IRL automatique',
    desc: 'Clark calcule et applique la révision annuelle des loyers selon l\'indice INSEE, sans oubli ni calcul manuel.',
  },
  {
    icon: Users,
    title: 'Gestion des candidatures',
    desc: 'Recevez, triez et validez les dossiers de candidature directement depuis votre tableau de bord.',
  },
  {
    icon: Bell,
    title: 'Alertes proactives',
    desc: 'Bail expirant, loyer impayé, DPE à renouveler — Clark vous alerte avant que ça devienne un problème.',
  },
  {
    icon: MapPin,
    title: 'Réseau d\'agents locaux',
    desc: 'Des intervenants de proximité prêts à intervenir à la demande pour les états des lieux, inspections et réparations.',
  },
  {
    icon: Shield,
    title: 'Conformité & juridique',
    desc: 'Veille réglementaire continue (loi Alur, Elan, loi Climat). Clark vous informe des évolutions qui vous concernent.',
  },
]

export default function Features() {
  return (
    <section id="fonctionnalites" className="section bg-white">
      <div className="container">
        <div className="text-center mb-16">
          <span className="tag mb-4">Fonctionnalités</span>
          <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
            Tout ce dont vous avez besoin,<br className="hidden md:block" /> rien de plus.
          </h2>
          <p className="text-gray-500 text-lg max-w-xl mx-auto">
            Clark couvre l'ensemble de la gestion locative — de la signature du bail
            à la résolution des incidents.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-5">
          {FEATURES.map(({ icon: Icon, title, desc, highlight }) => (
            <div
              key={title}
              className={`rounded-2xl p-6 border transition-all duration-200 hover:shadow-md hover:-translate-y-0.5 ${
                highlight
                  ? 'bg-clark-400 border-clark-400 col-span-1 md:col-span-2'
                  : 'bg-white border-gray-100'
              }`}
            >
              <div className={`w-10 h-10 rounded-xl flex items-center justify-center mb-4 ${
                highlight ? 'bg-white/20' : 'bg-clark-50'
              }`}>
                <Icon className={`w-5 h-5 ${highlight ? 'text-white' : 'text-clark-400'}`} />
              </div>
              <h3 className={`font-bold mb-2 ${highlight ? 'text-white' : 'text-gray-900'}`}>
                {title}
              </h3>
              <p className={`text-sm leading-relaxed ${highlight ? 'text-clark-100' : 'text-gray-500'}`}>
                {desc}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
