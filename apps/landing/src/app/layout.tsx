import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Clark Rent — Gestion locative simplifiée',
  description: 'Clark libère les propriétaires des contraintes de gestion et offre aux locataires un service réactif 24h/24.',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr" className="scroll-smooth">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet" />
      </head>
      <body className="font-sans antialiased">{children}</body>
    </html>
  )
}
