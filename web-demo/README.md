# Tuzday Web Demo

This folder contains a static web demo that runs Python in the browser using Pyodide and a CodeMirror-based editor. It's meant as a quick public demo you can deploy to Vercel or serve locally.

Files
- index.html — main page with editor and run button
- editor.js — glue that loads Pyodide and runs code
- style.css — basic responsive layout

Deploy on Vercel
1. Go to Vercel and Import Project -> choose Bitcoin-codes/Tuzday.
2. Set the Root Directory to `web-demo` during import so Vercel serves this folder.
3. Deploy. Vercel will give you a live URL.

Or deploy from your machine
1. Install Vercel CLI: `npm i -g vercel`
2. cd web-demo
3. Run `vercel --prod` and follow the prompts.

Notes
- Pyodide and CodeMirror are loaded from CDN for quick iteration. For production, consider bundling assets for offline use.
- This demo is independent from the Flutter app. It provides a public-facing preview of the Python execution experience (no file I/O or native features).
