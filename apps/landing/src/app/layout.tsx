import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Clark Rent — Votre gestion locative, simplifiée',
  description: 'Clark libère les propriétaires des contraintes de gestion et offre aux locataires un service réactif 24h/24. Réseau local d\'agents, application intuitive, expertise immobilière.',
  keywords: ['gestion locative', 'propriétaire', 'locataire', 'immobilier', 'Clark Rent'],
  openGraph: {
    title: 'Clark Rent — Gestion locative intelligente',
    description: 'Libérez-vous des contraintes de gestion locative avec Clark.',
    url: 'https://clarkrent.com',
    siteName: 'Clark Rent',
    locale: 'fr_FR',
    type: 'website',
  },
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr" className="scroll-smooth">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet" />
      </head>
      <body className="font-sans antialiased bg-white text-gray-900">{children}</body>
    </html>
  )
}
