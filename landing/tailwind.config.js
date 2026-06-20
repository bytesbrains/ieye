/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // Brand palette — derived from brand/ieye-logo-scene.png.
        // Warm paper base, charcoal guardian, beacon amber, twilight teal.
        // No alarm-red, no green "protected" shield anywhere.
        paper: {
          DEFAULT: "#f4efe1", // warm off-white (matches site.webmanifest theme_color)
          dim: "#ece5d3",
          deep: "#e3dac3",
        },
        charcoal: {
          DEFAULT: "#2b2f36", // lighthouse silhouette
          soft: "#3c424b",
          muted: "#5b626c",
          faint: "#7a818b",
        },
        amber: {
          // beacon-amber accent (the lamp / beam)
          DEFAULT: "#e8a33d",
          warm: "#f0b659",
          deep: "#cf8420",
        },
        teal: {
          // twilight-teal sky
          DEFAULT: "#5f8a93",
          soft: "#7ba3ab",
          deep: "#4a6f78",
        },
      },
      fontFamily: {
        sans: [
          "Inter",
          "ui-sans-serif",
          "system-ui",
          "-apple-system",
          "Segoe UI",
          "Roboto",
          "Helvetica Neue",
          "Arial",
          "sans-serif",
        ],
        serif: ["Newsreader", "Georgia", "Cambria", "Times New Roman", "serif"],
      },
      fontSize: {
        // 18px+ base for the elderly/family audience.
        base: ["1.125rem", { lineHeight: "1.7" }],
      },
      maxWidth: {
        prose: "42rem",
      },
      keyframes: {
        "beam-breathe": {
          "0%, 100%": { opacity: "0.55" },
          "50%": { opacity: "0.85" },
        },
        "fade-up": {
          "0%": { opacity: "0", transform: "translateY(12px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
      },
      animation: {
        // Gentle, calm motion only. Disabled under prefers-reduced-motion (see index.css).
        "beam-breathe": "beam-breathe 6s ease-in-out infinite",
        "fade-up": "fade-up 0.7s ease-out both",
      },
    },
  },
  plugins: [],
};
