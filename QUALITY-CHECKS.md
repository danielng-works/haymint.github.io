# Quality checks

Executed on 17 October 2026 in headless Chromium, served over local HTTP.

## Passed

- 0, 1 and 20 published items of EACH type at 375, 768 and 1280 pixels (nine combinations). Synthetic fixtures were injected into browser requests only; live JSON remains empty.
- All eight HTML pages, missing/published guide states, related products, combined category/subcategory/tag URL filters, every unique homepage chip URL, accent-insensitive search, zero-result search and empty states.
- Draft sentinel entries never appear in lists, search or guide detail.
- Empty Shopee URL hides shopping CTA; populated links have exact sponsored/nofollow/noopener attributes. Disclosure visibility follows actual affiliate links.
- Mobile menu toggle and Escape, one visible H1, alt attributes, no horizontal overflow, no uncaught exceptions or console errors in normal scenarios.
- Actual shipped empty files load correctly; unconfigured social links stay hidden. Example files are never loaded.
- Simulated fetch failure displays a friendly message (HTTP failure itself is expected to appear in browser network diagnostics).
- Both project-subdirectory and domain-root serving; nested guide fetch paths.
- Keyboard skip-link focus and visible outline; heading progression on empty home, guide list, missing guide and About.
- Static scan: no dead href="#", no root-absolute internal paths, no hardcoded github.io host in application HTML/CSS/JS, valid JSON, three draft examples/type, ASCII PowerShell source and UTF-8 files without BOM.
- Node JavaScript syntax check.
- Contrast calculations: charcoal/mint 5.47:1, muted/off-white 4.85:1, chip text/soft background 6.12:1. Hover button text was corrected to black on mint-hover after a lower-contrast combination was found. This is a sanity check, not a full WCAG audit.
- Desktop empty-state screenshot visually inspected. Fonts were mocked in browser automation, so screenshot uses system fallback.

## Not verified / limitations

- PowerShell 7 and Windows PowerShell 5.1 execution: neither runtime is installed. An attempted official runtime download was blocked (HTTP 403). No draft-script runtime test is claimed. tools/Test-HayMintTools.ps1 is included for disposable-copy testing in both shells, including Unicode round-trip and incomplete-item rejection.
- Authenticated Git add/commit/push and live GitHub Pages deployment, DNS, HTTPS, nested-host 404 behavior and social-sharing crawlers were not tested.
- Real Google Fonts loading, Safari/Firefox, physical devices, screen-reader behavior and a complete automated accessibility audit were not tested.
- Per-guide metadata is client-updated; non-JavaScript sharing crawlers see generic template metadata. No social image is bundled.
- No real Facebook Page URL or deployment URL was supplied. Set facebookPageUrl and baseUrl before publishing; initial sitemap intentionally has no fabricated URLs.
- Scripts check structure and local image existence, not editorial truth, image ownership, image decoding, remote URL availability or Shopee approval.
- Draft data in public JSON is not private.

## Browser matrix output

```text
PASS: 0 published items/type + draft sentinels; 375px; pages, chips, search, empty states, related products, disclosures, no overflow/errors.
PASS: 0 published items/type + draft sentinels; 768px; pages, chips, search, empty states, related products, disclosures, no overflow/errors.
PASS: 0 published items/type + draft sentinels; 1280px; pages, chips, search, empty states, related products, disclosures, no overflow/errors.
PASS: 1 published items/type + draft sentinels; 375px; pages, chips, search, empty states, related products, disclosures, no overflow/errors.
PASS: 1 published items/type + draft sentinels; 768px; pages, chips, search, empty states, related products, disclosures, no overflow/errors.
PASS: 1 published items/type + draft sentinels; 1280px; pages, chips, search, empty states, related products, disclosures, no overflow/errors.
PASS: 20 published items/type + draft sentinels; 375px; pages, chips, search, empty states, related products, disclosures, no overflow/errors.
PASS: 20 published items/type + draft sentinels; 768px; pages, chips, search, empty states, related products, disclosures, no overflow/errors.
PASS: 20 published items/type + draft sentinels; 1280px; pages, chips, search, empty states, related products, disclosures, no overflow/errors.
PASS: shipped empty JSON files, missing social URLs hidden, no example JSON loaded.
PASS: fetch failure displays a friendly message without uncaught JavaScript exceptions.
```
