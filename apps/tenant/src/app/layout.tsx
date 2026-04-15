import type { Metadata } from 'next'
import { Toaster } from 'react-hot-toast'
import { AuthProvider } from '@/contexts/AuthContext'
import AppShell from '@/components/AppShell'
import '@/styles/globals.css'

export const metadata: Metadata = {
  title: 'Clark — Espace locataire',
  description: 'Gérez votre location simplement avec Clark',
  viewport: 'width=device-width, initial-scale=1, maximum-scale=1',
  themeColor: '#449A84',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <body>
        <AuthProvider>
          <AppShell>{children}</AppShell>
          <Toaster
            position="top-center"
            toastOptions={{
              duration: 3000,
              style: {
                background: '#1A2E2A',
                color: '#fff',
                borderRadius: '12px',
                fontSize: '14px',
              },
              success: { iconTheme: { primary: '#449A84', secondary: '#fff' } },
            }}
          />
        </AuthProvider>
      </body>
    </html>
  )
}
