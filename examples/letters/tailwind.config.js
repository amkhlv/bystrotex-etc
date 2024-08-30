/** @type {import('tailwindcss').Config} */
const plugin = require('tailwindcss/plugin')
export default {
  content: [
    "./src/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      screens: {
        print: {raw: 'print'},
        screen: {raw: 'screen'},
      }
    },
  },
  plugins: [
    plugin(function({ addBase }) {
     addBase({
        'html': { fontSize: "12px" },
      })
    }),
  ],
}

