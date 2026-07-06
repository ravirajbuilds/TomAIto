# OrchardEye — landing page

A self-contained marketing site for OrchardEye. No build step, no dependencies —
plain HTML/CSS/JS. Structure inspired by clean agritech landers (hero → problem →
how-it-works → sensors → growers → rigor → pilot CTA), with OrchardEye's real content
and the same brand palette as the iOS app (`Color.brandLeaf` / amber / forest — see
[`../OrchardEye/OrchardEye/Views/Theme.swift`](../OrchardEye/OrchardEye/Views/Theme.swift)).

## Preview locally
```bash
cd web
python3 -m http.server 8000
# open http://localhost:8000
```

## Files
| File | Purpose |
|---|---|
| `index.html` | The single page (semantic sections, no framework). |
| `styles.css` | Design tokens + layout. Responsive, `prefers-reduced-motion` aware. |
| `main.js` | Scroll-reveal (IntersectionObserver) + sticky-nav shadow. Progressive enhancement — content works with JS off. |
| `favicon.svg`, `og-image.svg` | Icon + social preview. |

## Deploy (GitHub Pages)
Point Pages at this folder:
1. Repo **Settings → Pages → Build from a branch**.
2. Branch `main`, folder **`/web`** (or move these files to `/docs` if you prefer Pages' default).
3. Save — it publishes at `https://ravirajbuilds.github.io/tomaito/`.

> Edit the pilot `mailto:` and any copy before going live. "OrchardEye" is still a working name.
