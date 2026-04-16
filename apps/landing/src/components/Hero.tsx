import Link from 'next/link'
import { ArrowRight, Star } from 'lucide-react'

export default function Hero() {
  return (
    <section className="relative min-h-screen flex items-center overflow-hidden bg-clark-800">

      {/* Background pattern */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-20 left-10 w-72 h-72 bg-clark-400 rounded-full blur-3xl" />
        <div className="absolute bottom-20 right-10 w-96 h-96 bg-clark-300 rounded-full blur-3xl" />
      </div>

      {/* Grid overlay */}
      <div className="absolute inset-0"
        style={{ backgroundImage: 'radial-gradient(circle, rgba(68,154,132,0.08) 1px, transparent 1px)', backgroundSize: '40px 40px' }}
      />

      <div className="container relative pt-24 pb-16">
        <div className="max-w-3xl mx-auto text-center">

          {/* Badge */}
          <div className="inline-flex items-center gap-2 px-4 py-1.5 bg-white/10 backdrop-blur-sm
                          border border-white/20 rounded-full text-clark-200 text-sm font-medium mb-8">
            <div className="w-1.5 h-1.5 bg-clark-300 rounded-full animate-pulse" />
            Disponible à Saint-Brieuc — bientôt partout en France
          </div>

          {/* Titre */}
          <h1 className="text-4xl md:text-6xl lg:text-7xl font-extrabold text-white leading-[1.05] tracking-tight mb-6">
            Votre gestion{' '}
            <span className="text-clark-300">locative</span>
            <br />entre de bonnes mains.
          </h1>

          <p className="text-lg md:text-xl text-clark-100 leading-relaxed mb-10 max-w-2xl mx-auto">
            Clark libère les propriétaires des contraintes administratives
            et offre aux locataires un service réactif disponible 24h/24 —
            grâce à un réseau d'agents locaux et une IA dédiée.
          </p>

          {/* CTA */}
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-14">
            <Link href="#contact"
              className="btn-clark !px-8 !py-4 !text-base w-full sm:w-auto justify-center group"
            >
              Démarrer gratuitement
              <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </Link>
            <Link href="https://app.clarkrent.com"
              className="w-full sm:w-auto text-center px-8 py-4 bg-white/10 hover:bg-white/20
                         border border-white/20 text-white font-semibold text-base rounded-2xl
                         backdrop-blur-sm transition-all duration-200"
            >
              Voir la démo →
            </Link>
          </div>

          {/* Social proof */}
          <div className="flex items-center justify-center gap-6 text-clark-200">
            <div className="flex items-center gap-1.5">
              <div className="flex">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} className="w-4 h-4 fill-clark-300 text-clark-300" />
                ))}
              </div>
              <span className="text-sm font-medium">4.9/5</span>
            </div>
            <div className="w-px h-5 bg-white/20" />
            <span className="text-sm">+120 biens gérés</span>
            <div className="w-px h-5 bg-white/20" />
            <span className="text-sm">Pilote Saint-Brieuc</span>
          </div>
        </div>

        {/* App preview mockup */}
        <div className="mt-16 relative max-w-2xl mx-auto">
          <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-3xl p-4 shadow-2xl">
            <div className="bg-white rounded-2xl overflow-hidden shadow-xl">
              {/* Fake app header */}
              <div className="bg-clark-400 px-5 py-3 flex items-center gap-2">
                <div className="w-6 h-6 bg-white/20 rounded-lg flex items-center justify-center">
                  <span className="text-white font-bold text-xs">C</span>
                </div>
                <span className="text-white font-semibold text-sm">Clark</span>
              </div>
              {/* Fake chat UI */}
              <div className="p-5 space-y-3 bg-gray-50">
                <div className="flex gap-2.5 items-start">
                  <div className="w-7 h-7 bg-clark-400 rounded-full flex items-center justify-center flex-shrink-0">
                    <span className="text-white text-xs font-bold">C</span>
                  </div>
                  <div className="bg-white rounded-2xl rounded-bl-sm px-4 py-2.5 shadow-sm max-w-xs">
                    <p className="text-gray-800 text-sm">Bonjour Alice ! Comment puis-je vous aider aujourd'hui ? 👋</p>
                  </div>
                </div>
                <div className="flex justify-end">
                  <div className="bg-clark-400 text-white rounded-2xl rounded-br-sm px-4 py-2.5 max-w-xs">
                    <p className="text-sm">Ma chaudière est tombée en panne ce matin.</p>
                  </div>
                </div>
                <div className="flex gap-2.5 items-start">
                  <div className="w-7 h-7 bg-clark-400 rounded-full flex items-center justify-center flex-shrink-0">
                    <span className="text-white text-xs font-bold">C</span>
                  </div>
                  <div className="bg-white rounded-2xl rounded-bl-sm px-4 py-2.5 shadow-sm max-w-xs">
                    <p className="text-gray-800 text-sm">Ticket #847 créé en urgence ✓ Votre propriétaire est notifié. Un intervenant vous contactera sous 24h.</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
          {/* Floating badges */}
          <div className="absolute -right-4 top-8 bg-white rounded-2xl shadow-xl px-4 py-2.5 flex items-center gap-2 animate-float">
            <div className="w-2 h-2 bg-emerald-400 rounded-full" />
            <span className="text-xs font-semibold text-gray-700">Ticket créé en 3 sec</span>
          </div>
          <div className="absolute -left-4 bottom-8 bg-white rounded-2xl shadow-xl px-4 py-2.5 flex items-center gap-2 animate-float [animation-delay:2s]">
            <span className="text-lg">📄</span>
            <span className="text-xs font-semibold text-gray-700">Quittance générée</span>
          </div>
        </div>

      </div>
    </section>
  )
}
