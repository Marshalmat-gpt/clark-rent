'use client'

import { usePathname } from 'next/navigation'
import Link from 'next/link'
import { useAuth } from '@/contexts/AuthContext'
import { Home, MessageCircle, FileText, Wrench, LogOut } from 'lucide-react'
import clsx from 'clsx'

const NAV = [
  { href: '/dashboard', icon: Home,          label: 'Accueil' },
  { href: '/chat',      icon: MessageCircle, label: 'Clark' },
  { href: '/documents', icon: FileText,      label: 'Documents' },
  { href: '/incidents', icon: Wrench,        label: 'Incidents' },
]

export default function AppShell({ children }: { children: React.ReactNode }) {
  const pathname      = usePathname()
  const { user, logout } = useAuth()
  const isAuth        = pathname !== '/login'

  if (!isAuth) return <>{children}</>

  return (
    <div className="flex flex-col min-h-screen">

      {/* Header */}
      <header className="sticky top-0 z-30 bg-white border-b border-[--clark-border] px-4 h-14 flex items-center justify-between">
        <Link href="/dashboard" className="flex items-center gap-2">
          <div className="w-7 h-7 bg-clark-400 rounded-lg flex items-center justify-center">
            <span className="text-white font-bold text-sm">C</span>
          </div>
          <span className="font-semibold text-[--clark-text] tracking-tight">Clark</span>
        </Link>

        {user && (
          <div className="flex items-center gap-3">
            <div className="text-right hidden sm:block">
              <p className="text-xs font-medium text-[--clark-text]">{user.first_name} {user.last_name}</p>
              <p className="text-xs text-[--clark-muted]">{user.email}</p>
            </div>
            <button
              onClick={logout}
              className="w-8 h-8 rounded-lg hover:bg-gray-100 flex items-center justify-center text-[--clark-muted] hover:text-[--clark-text] transition-colors"
              title="Se déconnecter"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        )}
      </header>

      {/* Contenu */}
      <main className="flex-1 pb-20">
        {children}
      </main>

      {/* Navigation mobile — bottom bar */}
      <nav className="fixed bottom-0 left-0 right-0 z-30 bg-white border-t border-[--clark-border]
                      flex items-center justify-around h-16 px-2 safe-area-inset-bottom">
        {NAV.map(({ href, icon: Icon, label }) => {
          const active = pathname.startsWith(href)
          return (
            <Link
              key={href}
              href={href}
              className={clsx(
                'flex flex-col items-center gap-0.5 flex-1 py-2 rounded-xl transition-colors',
                active ? 'text-clark-400' : 'text-[--clark-muted] hover:text-[--clark-text]'
              )}
            >
              <Icon className={clsx('w-5 h-5 transition-transform', active && 'scale-110')} />
              <span className={clsx('text-[10px] font-medium', active && 'text-clark-400')}>
                {label}
              </span>
              {active && (
                <span className="absolute bottom-1 w-1 h-1 bg-clark-400 rounded-full" />
              )}
            </Link>
          )
        })}
      </nav>

    </div>
  )
}
