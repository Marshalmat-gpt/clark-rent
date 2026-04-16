const STEPS = [
  {
    number: '01',
    title: 'Inscrivez votre bien',
    description: 'En 5 minutes, ajoutez votre bien sur Clark. Adresse, surface, DPE — on s\'occupe du reste.',
    icon: '🏠',
    forOwner: true,
  },
  {
    number: '02',
    title: 'On gère tout',
    description: 'Quittances, révision IRL, candidatures, tickets d\'intervention — Clark automatise et vous alerte si besoin.',
    icon: '⚡',
    forOwner: true,
  },
  {
    number: '03',
    title: 'Vous encaissez',
    description: 'Recevez vos loyers, suivez vos revenus en temps réel, exportez pour votre comptable.',
    icon: '💰',
    forOwner: true,
  },
]

const TENANT_STEPS = [
  {
    number: '01',
    title: 'Votre espace personnel',
    description: 'Accédez à votre bail, vos quittances et tous vos documents en un instant depuis votre téléphone.',
    icon: '📱',
  },
  {
    number: '02',
    title: 'Signalez en 30 secondes',
    description: 'Un problème ? Signalez-le à Clark. Il crée le ticket, notifie le propriétaire et suit l\'intervention.',
    icon: '🔧',
  },
  {
    number: '03',
    title: 'Réponse en moins de 24h',
    description: 'Notre réseau d\'agents locaux intervient rapidement. Vous suivez l\'avancement en temps réel.',
    icon: '✅',
  },
]

export default function HowItWorks() {
  return (
    <section id="comment-ca-marche" className="section bg-gray-50">
      <div className="container">

        <div className="text-center mb-16">
          <span className="tag mb-4">Comment ça marche</span>
          <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
            Simple pour tout le monde.
          </h2>
          <p className="text-gray-500 text-lg max-w-xl mx-auto">
            Que vous soyez propriétaire ou locataire, Clark s'adapte à votre rôle.
          </p>
        </div>

        <div className="grid lg:grid-cols-2 gap-8">

          {/* Propriétaire */}
          <div className="bg-white rounded-3xl p-8 border border-gray-100 shadow-sm">
            <div className="flex items-center gap-3 mb-8">
              <div className="w-10 h-10 bg-clark-50 rounded-2xl flex items-center justify-center text-xl">🏡</div>
              <div>
                <p className="font-bold text-gray-900">Pour les propriétaires</p>
                <p className="text-sm text-gray-500">Gérez sans contraintes</p>
              </div>
            </div>
            <div className="space-y-6">
              {STEPS.map((step, i) => (
                <div key={step.number} className="flex gap-4">
                  <div className="flex flex-col items-center">
                    <div className="w-9 h-9 bg-clark-400 text-white rounded-xl flex items-center justify-center text-xs font-bold flex-shrink-0">
                      {step.number}
                    </div>
                    {i < STEPS.length - 1 && <div className="w-px flex-1 bg-clark-100 mt-2" />}
                  </div>
                  <div className="pb-6">
                    <p className="font-semibold text-gray-900 mb-1">{step.title}</p>
                    <p className="text-sm text-gray-500 leading-relaxed">{step.description}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Locataire */}
          <div className="bg-clark-800 rounded-3xl p-8">
            <div className="flex items-center gap-3 mb-8">
              <div className="w-10 h-10 bg-white/10 rounded-2xl flex items-center justify-center text-xl">🔑</div>
              <div>
                <p className="font-bold text-white">Pour les locataires</p>
                <p className="text-sm text-clark-300">Un service qui vous écoute</p>
              </div>
            </div>
            <div className="space-y-6">
              {TENANT_STEPS.map((step, i) => (
                <div key={step.number} className="flex gap-4">
                  <div className="flex flex-col items-center">
                    <div className="w-9 h-9 bg-clark-400 text-white rounded-xl flex items-center justify-center text-xs font-bold flex-shrink-0">
                      {step.number}
                    </div>
                    {i < TENANT_STEPS.length - 1 && <div className="w-px flex-1 bg-white/10 mt-2" />}
                  </div>
                  <div className="pb-6">
                    <p className="font-semibold text-white mb-1">{step.title}</p>
                    <p className="text-sm text-clark-200 leading-relaxed">{step.description}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

        </div>
      </div>
    </section>
  )
}
