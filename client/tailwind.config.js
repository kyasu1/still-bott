/** @type {import('tailwindcss').Config} */
//
// 下記を参考に設定
// https://sailboatui.com/docs/getting-started/quick-start/
//
const defaultTheme = require("tailwindcss/defaultTheme");
const colors = require("tailwindcss/colors");

module.exports = {
  content: ["./index.html", "./src/**/*.elm", "../templates/**/*.html"],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        primary: colors.blue,
        secondary: colors.slate
      }
    },
  },
  plugins: [require("@tailwindcss/typography"), require("@tailwindcss/forms"), require("daisyui")],
}

