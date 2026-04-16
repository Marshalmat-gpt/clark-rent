import { Star } from 'lucide-react'

const TESTIMONIALS = [
  {
    name: 'Thomas D.',
    role: 'Propriétaire · 3 biens',
    text: 'J\'avais peur de perdre le contrôle en déléguant. Avec Clark, c\'est l\'inverse — je vois tout en temps réel et je n\'ai plus à gérer les appels à 22h.',
    stars: 5,
    avatar: 'T',
  },
  {
    name: 'Alice M.',
    role: 'Locataire · Saint-Brieuc',
    text: 'Ma chaudière est tombée en panne un dimanche. J\'ai signalé sur l\'app, et un intervenant était chez moi le lundi matin. Impressionnant.',
    stars: 5,
    avatar: 'A',
  },
  {
    name: 'Marc L.',
    role: 'Propriétaire · 5 biens',
    text: 'Le calcul IRL automatique m\'a évité d\'oublier la révision deux années de suite. Sur 5 biens ça représente un vrai manque à gagner récupéré.',
    stars: 5,
    avatar: 'M',
  },
]

export default function Testimonials() {
  return (
    <section className="section bg-gray-50">
      <div className="container">
        <div className="text-center mb-14">
          <span className="tag mb-4">Témoignages</span>
          <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
            Ils font confiance à Clark.
          </h2>
        </div>

        <div className="grid md:grid-cols-3 gap-6">
          {TESTIMONIALS.map(({ name, role, text, stars, avatar }) => (
            <div key={name} className="bg-white rounded-2xl p-6 border border-gray-100 shadow-sm flex flex-col gap-4">
              <div className="flex gap-0.5">
                {[...Array(stars)].map((_, i) => (
                  <Star key={i} className="w-4 h-4 fill-clark-400 text-clark-400" />
                ))}
              </div>
              <p className="text-gray-700 text-sm leading-relaxed flex-1">"{text}"</p>
              <div className="flex items-center gap-3 pt-2 border-t border-gray-100">
                <div className="w-9 h-9 bg-clark-400 rounded-full flex items-center justify-center text-white font-bold text-sm flex-shrink-0">
                  {avatar}
                </div>
                <div>
                  <p className="font-semibold text-gray-900 text-sm">{name}</p>
                  <p className="text-gray-400 text-xs">{role}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
