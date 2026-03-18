import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from 'tailwindcss'
import autoprefixer from 'autoprefixer'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  css: {
    postcss: {
      plugins: [
        tailwindcss({
          content: [
            "./index.html",
            "./src/**/*.{js,ts,jsx,tsx}",
          ],
          theme: {
            extend: {
              colors: {
                navy: {
                  950: '#0a0f1e',
                  900: '#0f172a',
                  800: '#1e293b',
                  700: '#334155',
                }
              },
              fontFamily: {
                inter: ['Inter', 'sans-serif'],
              },
            },
          },
          plugins: [],
        }),
        autoprefixer(),
      ],
    },
  },
})
