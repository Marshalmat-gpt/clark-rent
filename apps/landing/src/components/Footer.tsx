import Link from 'next/link'

const LINKS = {
  'Produit':     ['Comment ça marche', 'Fonctionnalités', 'Tarifs'],
  'Ressources':  ['Blog', 'Guide propriétaire', 'Guide locataire'],
  'Légal':       ['Mentions légales', 'Politique de confidentialité', 'CGU'],
  'Accès':       ['Espace locataire', 'Espace propriétaire', 'Support'],
}

export default function Footer() {
  return (
    <footer className="bg-gray-950 text-gray-400">
      <div className="container py-14">
        <div className="grid grid-cols-2 md:grid-cols-5 gap-8 mb-12">
          {/* Brand */}
          <div className="col-span-2 md:col-span-1">
            <div className="flex items-center gap-2.5 mb-4">
              <div className="w-8 h-8 bg-clark-400 rounded-xl flex items-center justify-center">
                <span className="text-white font-bold text-base">C</span>
              </div>
              <span className="text-white font-bold tracking-tight">Clark</span>
            </div>
            <p className="text-sm leading-relaxed text-gray-500">
              La gestion locative intelligente pour les propriétaires et les locataires.
            </p>
          </div>

          {/* Links */}
          {Object.entries(LINKS).map(([section, items]) => (
            <div key={section}>
              <h4 className="text-white font-semibold text-sm mb-4">{section}</h4>
              <ul className="space-y-2.5">
                {items.map((item) => (
                  <li key={item}>
                    <a href="#" className="text-sm text-gray-500 hover:text-clark-400 transition-colors">
                      {item}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="border-t border-white/5 pt-8 flex flex-col md:flex-row items-center justify-between gap-4">
          <p className="text-sm text-gray-600">
            © {new Date().getFullYear()} Clark Rent — Gestion locative intelligente
          </p>
          <p className="text-xs text-gray-700">
            Pilote lancé à Saint-Brieuc (22) · Bientôt disponible partout en France
          </p>
        </div>
      </div>
    </footer>
  )
}
