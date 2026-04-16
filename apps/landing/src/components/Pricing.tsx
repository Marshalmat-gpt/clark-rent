import { Check } from 'lucide-react'
import Link from 'next/link'

const PLANS = [
  {
    name: 'Starter',
    price: '3%',
    period: 'du loyer / bien',
    desc: 'Pour commencer sans risque',
    features: [
      'Quittancement automatique',
      'Révision IRL',
      'Assistant Clark (locataire)',
      'Signalement d\'incidents',
      'Documents en ligne',
    ],
    cta: 'Commencer gratuitement',
    href: '#contact',
    highlighted: false,
  },
  {
    name: 'Pro',
    price: '3%',
    period: '+ 100€/EDL + 100€/intervention',
    desc: 'La solution complète',
    features: [
      'Tout Starter inclus',
      'États des lieux (entrée & sortie)',
      'Interventions à la demande',
      'Réseau d\'agents locaux',
      'Assistant Clark (propriétaire)',
      'Alertes & veille juridique',
      'Export comptable',
    ],
    cta: 'Démarrer avec Pro',
    href: '#contact',
    highlighted: true,
  },
  {
    name: 'Parc',
    price: 'Sur devis',
    period: 'à partir de 10 biens',
    desc: 'Pour les gestionnaires de parc',
    features: [
      'Tout Pro inclus',
      'Tableau de bord multi-biens',
      'Reporting mensuel',
      'Accompagnement dédié',
      'Intégration comptabilité',
    ],
    cta: 'Nous contacter',
    href: '#contact',
    highlighted: false,
  },
]

export default function Pricing() {
  return (
    <section id="tarifs" className="section bg-white">
      <div className="container">
        <div className="text-center mb-14">
          <span className="tag mb-4">Tarifs</span>
          <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
            Transparent. Sans surprise.
          </h2>
          <p className="text-gray-500 text-lg max-w-xl mx-auto">
            Vous ne payez que sur les loyers encaissés. Pas de frais fixes, pas d'engagement.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-6 items-start">
          {PLANS.map(({ name, price, period, desc, features, cta, href, highlighted }) => (
            <div
              key={name}
              className={`rounded-3xl p-7 border flex flex-col gap-6 ${
                highlighted
                  ? 'bg-clark-800 border-clark-700 shadow-2xl shadow-clark-400/20 scale-105'
                  : 'bg-white border-gray-100 shadow-sm'
              }`}
            >
              {highlighted && (
                <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-clark-400 rounded-full text-white text-xs font-semibold w-fit">
                  ⭐ Le plus populaire
                </div>
              )}
              <div>
                <p className={`font-bold text-lg mb-1 ${highlighted ? 'text-white' : 'text-gray-900'}`}>{name}</p>
                <div className="flex items-baseline gap-1">
                  <span className={`text-3xl font-extrabold ${highlighted ? 'text-clark-300' : 'text-clark-400'}`}>
                    {price}
                  </span>
                </div>
                <p className={`text-xs mt-0.5 ${highlighted ? 'text-clark-300' : 'text-gray-400'}`}>{period}</p>
                <p className={`text-sm mt-2 ${highlighted ? 'text-clark-200' : 'text-gray-500'}`}>{desc}</p>
              </div>

              <ul className="space-y-2.5 flex-1">
                {features.map((f) => (
                  <li key={f} className="flex items-start gap-2.5">
                    <div className={`w-4 h-4 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5 ${
                      highlighted ? 'bg-clark-400' : 'bg-clark-50'
                    }`}>
                      <Check className={`w-2.5 h-2.5 ${highlighted ? 'text-white' : 'text-clark-400'}`} />
                    </div>
                    <span className={`text-sm ${highlighted ? 'text-clark-100' : 'text-gray-600'}`}>{f}</span>
                  </li>
                ))}
              </ul>

              <Link href={href}
                className={`text-center py-3 px-6 rounded-2xl font-semibold text-sm transition-all ${
                  highlighted
                    ? 'bg-clark-400 text-white hover:bg-clark-300'
                    : 'bg-gray-900 text-white hover:bg-gray-700'
                }`}
              >
                {cta}
              </Link>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
