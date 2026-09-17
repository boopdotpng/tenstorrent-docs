# Offline browser dependencies

- marked 18.0.13, `lib/marked.umd.js`, MIT (MARKED-LICENSE.md).
- DOMPurify 3.4.15, `dist/purify.min.js`, Apache-2.0 OR MPL-2.0 (DOMPURIFY-LICENSE).

Fetched from their npm packages on September 17, 2026. Both are vendored so the
viewer needs no CDN, npm install, or internet connection at runtime. Markdown
HTML is sanitized before display. Update the pinned files and licenses together.
