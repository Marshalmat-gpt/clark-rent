'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { Menu, X } from 'lucide-react'
import clsx from 'clsx'

const NAV_LINKS = [
  { href: '#comment-ca-marche', label: 'Comment ça marche' },
  { href: '#fonctionnalites',   label: 'Fonctionnalités' },
  { href: '#tarifs',            label: 'Tarifs' },
  { href: '#contact',           label: 'Contact' },
]

export default function Navbar() {
  const [open,      setOpen]      = useState(false)
  const [scrolled,  setScrolled]  = useState(false)

  useEffect(() => {
    const handler = () => setScrolled(window.scrollY > 20)
    window.addEventListener('scroll', handler)
    return () => window.removeEventListener('scroll', handler)
  }, [])

  return (
    <header className={clsx(
      'fixed top-0 left-0 right-0 z-50 transition-all duration-300',
      scrolled ? 'bg-white/95 backdrop-blur-sm shadow-sm' : 'bg-transparent'
    )}>
      <div className="container flex items-center justify-between h-16">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2.5">
          <div className="w-8 h-8 bg-clark-400 rounded-xl flex items-center justify-center">
            <span className="text-white font-bold text-base">C</span>
          </div>
          <span className={clsx(
            'font-bold text-lg tracking-tight transition-colors',
            scrolled ? 'text-gray-900' : 'text-white'
          )}>Clark</span>
        </Link>

        {/* Nav desktop */}
        <nav className="hidden md:flex items-center gap-6">
          {NAV_LINKS.map(({ href, label }) => (
            <a key={href} href={href}
              className={clsx(
                'text-sm font-medium transition-colors hover:text-clark-400',
                scrolled ? 'text-gray-600' : 'text-white/80'
              )}
            >
              {label}
            </a>
          ))}
        </nav>

        {/* CTA desktop */}
        <div className="hidden md:flex items-center gap-3">
          <Link href="https://app.clarkrent.com/login"
            className={clsx(
              'text-sm font-medium transition-colors',
              scrolled ? 'text-gray-600 hover:text-clark-400' : 'text-white/80 hover:text-white'
            )}
          >
            Se connecter
          </Link>
          <Link href="#contact" className="btn-clark !py-2 !px-4 !text-sm !shadow-none">
            Commencer gratuitement
          </Link>
        </div>

        {/* Burger mobile */}
        <button
          className={clsx('md:hidden p-2 rounded-lg', scrolled ? 'text-gray-700' : 'text-white')}
          onClick={() => setOpen(!open)}
        >
          {open ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
      </div>

      {/* Menu mobile */}
      {open && (
        <div className="md:hidden bg-white border-t border-gray-100 px-5 py-4 flex flex-col gap-3">
          {NAV_LINKS.map(({ href, label }) => (
            <a key={href} href={href} onClick={() => setOpen(false)}
              className="text-sm font-medium text-gray-700 hover:text-clark-400 py-1"
            >
              {label}
            </a>
          ))}
          <div className="pt-3 border-t border-gray-100 flex flex-col gap-2">
            <Link href="https://app.clarkrent.com/login"
              className="text-sm text-center font-medium text-gray-600 py-2"
            >
              Se connecter
            </Link>
            <Link href="#contact" className="btn-clark justify-center">
              Commencer gratuitement
            </Link>
          </div>
        </div>
      )}
    </header>
  )
}
