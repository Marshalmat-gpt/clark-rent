'use client'

import { useEffect, useRef, useState } from 'react'
import api from '@/lib/api'
import { useAuth } from '@/contexts/AuthContext'
import { Send, Download, Loader2 } from 'lucide-react'
import clsx from 'clsx'

interface Message {
  role: 'user' | 'assistant'
  content: string
}

interface Action {
  type: 'download_url'
  url: string
  label: string
}

const SUGGESTIONS = [
  'Quel est mon loyer ce mois-ci ?',
  'Télécharger ma dernière quittance',
  'Signaler une panne',
  'Mon bail se termine quand ?',
]

export default function ChatPage() {
  const { user }                      = useAuth()
  const bottomRef                     = useRef<HTMLDivElement>(null)
  const inputRef                      = useRef<HTMLInputElement>(null)
  const [messages, setMessages]       = useState<Message[]>([])
  const [history, setHistory]         = useState<any[]>([])
  const [actions, setActions]         = useState<Action[]>([])
  const [input, setInput]             = useState('')
  const [loading, setLoading]         = useState(false)
  const [showSuggestions, setShowSuggestions] = useState(true)

  // Message d'accueil
  useEffect(() => {
    setMessages([{
      role: 'assistant',
      content: `Bonjour ${user?.first_name} 👋 Je suis Clark, votre assistant. Comment puis-je vous aider aujourd'hui ?`,
    }])
  }, [user])

  // Scroll automatique vers le bas
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, loading])

  const send = async (text: string) => {
    if (!text.trim() || loading) return

    const userMsg: Message = { role: 'user', content: text }
    setMessages((prev) => [...prev, userMsg])
    setInput('')
    setLoading(true)
    setShowSuggestions(false)
    setActions([])

    try {
      const { data } = await api.post('/agent/chat', {
        message: text,
        history,
      })

      const assistantMsg: Message = { role: 'assistant', content: data.reply }
      setMessages((prev) => [...prev, assistantMsg])
      setHistory(data.history)
      if (data.actions?.length) setActions(data.actions)
    } catch {
      setMessages((prev) => [
        ...prev,
        { role: 'assistant', content: 'Désolé, une erreur est survenue. Réessayez dans un instant.' },
      ])
    } finally {
      setLoading(false)
      inputRef.current?.focus()
    }
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    send(input)
  }

  return (
    <div className="flex flex-col h-[calc(100vh-4rem)] max-w-2xl mx-auto">

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-4 py-5 flex flex-col gap-4">

        {messages.map((msg, i) => (
          <div
            key={i}
            className={clsx('flex', msg.role === 'user' ? 'justify-end' : 'justify-start')}
          >
            {msg.role === 'assistant' && (
              <div className="w-8 h-8 bg-clark-400 rounded-full flex items-center justify-center flex-shrink-0 mr-2 mt-0.5">
                <span className="text-white text-xs font-bold">C</span>
              </div>
            )}
            <div className={msg.role === 'user' ? 'chat-bubble-user' : 'chat-bubble-clark'}>
              <p className="leading-relaxed whitespace-pre-wrap">{msg.content}</p>
            </div>
          </div>
        ))}

        {/* Indicateur de saisie */}
        {loading && (
          <div className="flex justify-start">
            <div className="w-8 h-8 bg-clark-400 rounded-full flex items-center justify-center mr-2">
              <span className="text-white text-xs font-bold">C</span>
            </div>
            <div className="chat-bubble-clark flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 bg-clark-400 rounded-full animate-bounce [animation-delay:0ms]"/>
              <span className="w-1.5 h-1.5 bg-clark-400 rounded-full animate-bounce [animation-delay:150ms]"/>
              <span className="w-1.5 h-1.5 bg-clark-400 rounded-full animate-bounce [animation-delay:300ms]"/>
            </div>
          </div>
        )}

        {/* Actions (boutons de téléchargement) */}
        {actions.map((action, i) => (
          <div key={i} className="flex justify-start pl-10">
            <a
              href={action.url}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 px-4 py-2 bg-white border border-clark-200 text-clark-400
                         text-sm font-medium rounded-xl hover:bg-clark-50 transition-colors"
            >
              <Download className="w-4 h-4" />
              {action.label}
            </a>
          </div>
        ))}

        {/* Suggestions initiales */}
        {showSuggestions && messages.length === 1 && (
          <div className="flex flex-col gap-2 pl-10">
            {SUGGESTIONS.map((s) => (
              <button
                key={s}
                onClick={() => send(s)}
                className="text-left text-sm px-4 py-2.5 bg-white border border-[--clark-border]
                           rounded-xl text-[--clark-text] hover:border-clark-300 hover:bg-clark-50
                           transition-colors"
              >
                {s}
              </button>
            ))}
          </div>
        )}

        <div ref={bottomRef} />
      </div>

      {/* Zone de saisie */}
      <div className="border-t border-[--clark-border] bg-white px-4 py-3">
        <form onSubmit={handleSubmit} className="flex items-center gap-2">
          <input
            ref={inputRef}
            type="text"
            className="input flex-1 !py-2"
            placeholder="Posez votre question à Clark…"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            disabled={loading}
            autoComplete="off"
          />
          <button
            type="submit"
            disabled={!input.trim() || loading}
            className="w-10 h-10 bg-clark-400 hover:bg-clark-500 disabled:opacity-40 disabled:cursor-not-allowed
                       text-white rounded-xl flex items-center justify-center transition-colors flex-shrink-0"
          >
            {loading
              ? <Loader2 className="w-4 h-4 animate-spin" />
              : <Send className="w-4 h-4" />
            }
          </button>
        </form>
        <p className="text-center text-xs text-[--clark-muted] mt-2">
          Clark peut faire des erreurs. Vérifiez les informations importantes.
        </p>
      </div>

    </div>
  )
}
