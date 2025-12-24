cat > setup_aurelius.sh << 'EOF'
#!/bin/bash
set -e

# 1. Setup Directories
echo "Creating project structure..."
mkdir -p aurelius_app/src/components
mkdir -p aurelius_app/src/services
mkdir -p aurelius_app/src/utils
cd aurelius_app

# 2. Configuration Files
echo "Writing config files..."

cat > package.json << 'INNEREOF'
{
  "name": "aurelius-echo",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "start": "node server.js"
  },
  "dependencies": {
    "@google/genai": "^0.1.1",
    "dotenv": "^16.4.5",
    "express": "^4.18.2",
    "lucide-react": "^0.344.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/react": "^18.2.64",
    "@types/react-dom": "^18.2.21",
    "@vitejs/plugin-react": "^4.2.1",
    "autoprefixer": "^10.4.18",
    "postcss": "^8.4.35",
    "tailwindcss": "^3.4.1",
    "typescript": "^5.4.2",
    "vite": "^5.1.6"
  }
}
INNEREOF

cat > tsconfig.json << 'INNEREOF'
{
  "compilerOptions": {
    "target": "ES2020", "useDefineForClassFields": true, "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext", "skipLibCheck": true, "moduleResolution": "bundler",
    "allowImportingTsExtensions": true, "resolveJsonModule": true, "isolatedModules": true,
    "noEmit": true, "jsx": "react-jsx", "strict": true, "noUnusedLocals": false,
    "noUnusedParameters": false, "noFallthroughCasesInSwitch": true
  },
  "include": ["src/**/*.ts", "src/**/*.tsx"], "exclude": ["node_modules"]
}
INNEREOF

cat > vite.config.ts << 'INNEREOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
export default defineConfig({
  plugins: [react()],
  define: { 'process.env.API_KEY': JSON.stringify(process.env.API_KEY) },
});
INNEREOF

cat > index.html << 'INNEREOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <title>Aurelius Echo</title>
    <link rel="manifest" href="/manifest.json">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
      tailwind.config = {
        theme: {
          extend: {
            fontFamily: { serif: ['Georgia', 'serif'], sans: ['"Inter"', 'sans-serif'] },
            colors: { stone: { 800: '#292524', 900: '#1c1917', 950: '#0c0a09' }, gold: { 500: '#d4af37', 600: '#b08d26' } }
          }
        }
      }
    </script>
    <style>body { background-color: #0c0a09; color: #e7e5e4; -webkit-font-smoothing: antialiased; } .pb-safe { padding-bottom: env(safe-area-inset-bottom); }</style>
  </head>
  <body><div id="root"></div><script type="module" src="/src/index.tsx"></script></body>
</html>
INNEREOF

cat > manifest.json << 'INNEREOF'
{
  "name": "Aurelius Echo", "short_name": "Aurelius", "start_url": "/", "display": "standalone",
  "background_color": "#0c0a09", "theme_color": "#0c0a09", "orientation": "portrait",
  "icons": [ { "src": "https://api.iconify.design/lucide:book-open.svg?color=%23d4af37", "sizes": "192x192", "type": "image/svg+xml" } ]
}
INNEREOF
EOF