import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "tailwindcss";

export default defineConfig({
  server: {
    host: '127.0.0.1',
    port: 3000
  },
  plugins: [react()],

  define: {
    global: "globalThis",
  },
  css: {
    postcss: {
      plugins: [tailwindcss()],
    },
  },
});
