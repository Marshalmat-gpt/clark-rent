const STATS = [
  { value: '120+',  label: 'Biens gérés',           sub: 'sur Saint-Brieuc' },
  { value: '< 24h', label: 'Délai d\'intervention',  sub: 'pour les urgences' },
  { value: '98%',   label: 'Propriétaires satisfaits', sub: 'sur le pilote' },
  { value: '0€',    label: 'Frais de mise en route',  sub: 'sans engagement' },
]

export default function Stats() {
  return (
    <section className="bg-clark-400 py-12">
      <div className="container">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-6 lg:gap-8">
          {STATS.map(({ value, label, sub }) => (
            <div key={label} className="text-center">
              <p className="text-3xl lg:text-4xl font-extrabold text-white mb-1">{value}</p>
              <p className="text-clark-100 font-semibold text-sm">{label}</p>
              <p className="text-clark-200 text-xs mt-0.5">{sub}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
