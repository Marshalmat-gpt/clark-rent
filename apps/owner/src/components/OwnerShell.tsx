'use client'

import { usePathname } from 'next/navigation'
import Link from 'next/link'
import { useAuth } from '@/contexts/AuthContext'
import {
  LayoutDashboard, Home, Users, Wrench,
  MessageCircle, LogOut, ChevronRight
} from 'lucide-react'
import clsx from 'clsx'

const NAV = [
  { href: '/dashboard',    icon: LayoutDashboard, label: 'Tableau de bord' },
  { href: '/properties',   icon: Home,            label: 'Mes biens' },
  { href: '/applications', icon: Users,           label: 'Candidatures' },
  { href: '/tickets',      icon: Wrench,          label: 'Interventions' },
  { href: '/chat',         icon: MessageCircle,   label: 'Assistant Clark' },
]

export default function OwnerShell({ children }: { children: React.ReactNode }) {
  const pathname         = usePathname()
  const { user, logout } = useAuth()
  const isAuth           = pathname !== '/login'

  if (!isAuth) return <>{children}</>

  return (
    <div className="flex min-h-screen">

      {/* Sidebar desktop */}
      <aside className="hidden lg:flex w-60 flex-col bg-[--dark] fixed h-full z-30">
        {/* Logo */}
        <div className="flex items-center gap-3 px-5 py-5 border-b border-white/10">
          <div className="w-8 h-8 bg-clark-400 rounded-xl flex items-center justify-center flex-shrink-0">
            <span className="text-white font-bold text-sm">C</span>
          </div>
          <div>
            <span className="text-white font-semibold tracking-tight text-sm">Clark</span>
            <span className="text-clark-400 text-xs font-medium ml-1">Pro</span>
          </div>
        </div>

        {/* Nav */}
        <nav className="flex-1 px-3 py-4 space-y-1">
          {NAV.map(({ href, icon: Icon, label }) => {
            const active = pathname.startsWith(href)
            return (
              <Link key={href} href={href}
                className={clsx(
                  'flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all',
                  active
                    ? 'bg-clark-400 text-white'
                    : 'text-gray-400 hover:bg-white/10 hover:text-white'
                )}
              >
                <Icon className="w-4 h-4 flex-shrink-0" />
                {label}
              </Link>
            )
          })}
        </nav>

        {/* User */}
        {user && (
          <div className="px-3 pb-4 border-t border-white/10 pt-4">
            <div className="flex items-center gap-3 px-3 py-2.5 rounded-xl">
              <div className="w-8 h-8 bg-clark-400/20 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-clark-400 font-semibold text-sm">
                  {user.first_name?.charAt(0)}
                </span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-white text-xs font-medium truncate">{user.first_name} {user.last_name}</p>
                <p className="text-gray-500 text-xs truncate">{user.email}</p>
              </div>
              <button
                onClick={logout}
                className="text-gray-500 hover:text-white transition-colors"
                title="Se déconnecter"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}
      </aside>

      {/* Contenu principal */}
      <div className="flex-1 lg:ml-60 flex flex-col min-h-screen">

        {/* Header mobile */}
        <header className="lg:hidden sticky top-0 z-20 bg-white border-b border-[--border] px-4 h-14 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 bg-clark-400 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-xs">C</span>
            </div>
            <span className="font-semibold text-sm">Clark <span className="text-clark-400">Pro</span></span>
          </div>
          {user && (
            <button onClick={logout} className="text-[--muted] hover:text-[--text]">
              <LogOut className="w-4 h-4" />
            </button>
          )}
        </header>

        <main className="flex-1 p-5 lg:p-8 pb-24 lg:pb-8">
          {children}
        </main>

        {/* Nav mobile bottom */}
        <nav className="lg:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-[--border]
                        flex items-center justify-around h-16 z-20">
          {NAV.slice(0, 5).map(({ href, icon: Icon, label }) => {
            const active = pathname.startsWith(href)
            return (
              <Link key={href} href={href}
                className={clsx(
                  'flex flex-col items-center gap-0.5 flex-1 py-2 transition-colors',
                  active ? 'text-clark-400' : 'text-[--muted]'
                )}
              >
                <Icon className="w-5 h-5" />
                <span className="text-[10px] font-medium">{label.split(' ')[0]}</span>
              </Link>
            )
          })}
        </nav>
      </div>

    </div>
  )
}
