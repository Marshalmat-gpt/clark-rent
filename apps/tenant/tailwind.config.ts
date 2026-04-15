import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        clark: {
          50:  '#edf7f4',
          100: '#c8e9e1',
          200: '#96d3c5',
          300: '#64bca8',
          400: '#449A84', // Couleur principale Clark
          500: '#337a69',
          600: '#265c4f',
          700: '#1a3d34',
          800: '#0d1f1a',
          900: '#060f0d',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      borderRadius: {
        xl:  '1rem',
        '2xl': '1.25rem',
        '3xl': '1.5rem',
      },
      boxShadow: {
        card: '0 1px 3px 0 rgba(0,0,0,0.06), 0 1px 2px -1px rgba(0,0,0,0.06)',
        'card-hover': '0 4px 12px 0 rgba(0,0,0,0.08)',
      },
    },
  },
  plugins: [],
}

export default config
