# HayMint

**Đồ hay. Sống tiện.** A Vietnamese recommendation channel, not a store.
Plain HTML, CSS and vanilla JavaScript. No npm, framework, backend, embeds, or build step.

## Start here

1. Extract this archive. Copy the **contents** of `haymint/` to your repository root, including `.nojekyll`.
2. Edit `data/config.json`: set `facebookPageUrl` to your actual Page URL and `baseUrl` to the full deployed site URL, including the repository path when applicable and preferably a trailing slash. Other social URLs can remain empty.
3. Preview from the repository root: `python -m http.server 8000`, then open `http://localhost:8000/`. Do not double-click HTML: fetch needs HTTP.
4. Test the empty site first. The hero, updating message, navigation, About and disclosure remain available. Empty content sections, category cards and newsletter are hidden until there is published content. Facebook links are hidden until a real URL is configured. No placeholder Facebook account is invented.
5. Add your first **real, original Reels**, thumbnail and duration before showing the site to reviewers. Do not publish the examples.
6. Run `tools/Publish-HayMint.ps1 -ValidateOnly` to validate and refresh SEO without Git operations. This changes sitemap, robots, canonical/OG URLs and homepage Organization metadata; it does not commit or push.

All three LIVE content files ship as `[]`. The three `*.example.json` files contain exactly three drafts each and are never fetched by the site. Draft is a visibility flag, **not privacy**: JSON and repository files on a public site are publicly accessible. Never store secrets or private drafts here.

## Configuration and portability

`config.json` contains `siteName`, `tagline`, `baseUrl`, `facebookPageUrl`, `tiktokUrl`, `youtubeUrl`, `instagramUrl`.
Navigation, assets, fetch paths and JSON image paths are relative to the repository. JavaScript derives the root from its own script URL, including inside `guides/`. There is no hardcoded GitHub account/domain in application code.

On a custom-domain move, change **configuration only**, rerun Publish, and configure DNS/Pages. No application-code edits are needed. Canonical/OG URLs and sitemap URLs are intentionally absolute after publishing because they identify the public deployment. External fonts, social links, affiliate links and schema vocabulary are also necessarily absolute. These are not root-absolute internal asset paths.

`baseUrl` and Facebook URL are deliberately empty in the download because your real URLs were not provided. Publishing blocks until both are set. The initial sitemap is a valid empty URL set, not a fake deployment URL. Publish regenerates it from static pages, nonempty published categories and published guides only. Draft guide URLs are excluded.

## Add content with PowerShell

Scripts target Windows PowerShell 5.1 and PowerShell 7. They use .NET UTF-8 reads and UTF-8 **without BOM** writes. Script source is ASCII to avoid Windows PowerShell 5.1 misreading non-ASCII source without BOM. Vietnamese arguments and JSON remain Unicode. Run from a Unicode-capable terminal. Do not bypass your organization's execution policies.

### Product

```powershell
.\tools\New-HayMintItem.ps1 -Type product -Name "Hộp lưu trữ gấp gọn" -Category living -Subcategory luu-tru -Tags "phòng nhỏ","gấp gọn" -Description "Gợi ý sắp xếp vật dụng theo nhu cầu."
```

This creates a draft and prints its ID, normally `hop-luu-tru-gap-gon`. Duplicate IDs receive `-2`, `-3`, etc. Add your own photo at `assets/img/products/hop-luu-tru.jpg`, then edit `image` in JSON. Keep `shopeeUrl` empty before affiliate approval. A published product **may have no affiliate link**; no buy button or one-line disclosure appears for that product alone.

### Video

```powershell
.\tools\New-HayMintItem.ps1 -Type video -Name "Góc bàn gọn hơn" -Category desk -Subcategory hub-cong-ket-noi -VideoUrl "<your real Facebook Reel HTTPS URL>" -Image "assets/img/videos/goc-ban.jpg" -Duration "00:30" -Status published
```

Replace the URL placeholder and create your own thumbnail **before** running this published example. `-VideoUrl` maps to `url` for a video and `videoUrl` for a product. `-Image` maps to `thumbnail` for a video. Published videos require a Facebook/fb.watch URL, duration and existing thumbnail. The URL host is validated, not the video's availability or ownership.

### Guide

```powershell
$sections = @(
    @{ heading = "Bắt đầu từ nhu cầu"; paragraphs = @("Đo không gian trước khi lựa chọn.", "Nhóm vật dụng theo tần suất sử dụng.") }
)
.\tools\New-HayMintItem.ps1 -Type guide -Name "Sắp xếp góc làm việc" -Category desk -Subcategory phu-kien-ban -Description "Một vài gợi ý cho góc bàn ngăn nắp." -Sections $sections -Tags "phòng nhỏ"
```

`-Description` maps to guide `intro`. `-RelatedProductIds` accepts product IDs. Only published products can be referenced by a published guide at publish time. Sections are objects with optional `heading` and `paragraphs` arrays of plain text. No raw HTML is interpreted. Use a paragraph beginning `Hình minh họa được tạo bằng AI.` if a realistic AI illustration is ever added through a future content extension. The current schema only displays original product photos and original video thumbnails, not generated product imagery.

### Publish or unpublish an item

```powershell
.\tools\Set-HayMintStatus.ps1 -Type product -Id "hop-luu-tru-gap-gon" -Status published
.\tools\Set-HayMintStatus.ps1 -Type product -Id "hop-luu-tru-gap-gon" -Status draft
.\tools\Set-HayMintStatus.ps1 -Type video -Id "goc-ban-gon-hon" -Status published
.\tools\Set-HayMintStatus.ps1 -Type guide -Id "sap-xep-goc-lam-viec" -Status published
```

Publishing validates completeness first; incomplete entries are not written. Drafts can be unfinished. Unpublishing a product also requires removing it from published guides' `relatedProductIds` (or unpublishing those guides) before the repository can pass validation.

### Validate, commit and push

```powershell
.\tools\Publish-HayMint.ps1 -ValidateOnly
.\tools\Publish-HayMint.ps1 -Message "Add video"
```

Requires an initialized Git repository, configured identity, remote and upstream branch. `Publish` parses every data JSON, validates taxonomy/status/duplicates, checks **all nonempty image references** in live files (including drafts), validates published fields and HTTPS links, verifies related products, refreshes SEO, then runs `git add --all`, commits if needed and pushes. Review your working tree first: **all changes are staged**. The script cannot verify product claims, image ownership, Shopee approval, link destination content or whether a Reel really exists. Human editorial review is still required. Blank affiliate URLs are allowed; nonempty invalid URLs are rejected.

## Manual JSON editing

1. Copy a draft object from the matching example file into the live array, or use New-HayMintItem.
2. Keep IDs/slugs unique, use taxonomy slugs exactly, and keep `tags`, `sections`, `paragraphs`, `relatedProductIds` as arrays even with one entry.
3. Products: `id,name,category,subcategory,tags,image,description,shopeeUrl,videoUrl,status,updatedAt`.
4. Videos: `id,title,duration,thumbnail,url,category,subcategory,tags,status,publishedAt`.
5. Guides: `slug,title,intro,sections,relatedProductIds,category,subcategory,tags,status,updatedAt`.
6. Dates use `yyyy-MM-dd`. Image paths use ASCII filenames and `/`, under `assets/img/`; products must use `assets/img/products/`.
7. Change `status` to `published` only when real and complete. To unpublish, set `draft`. Refresh the site to see changes.
8. Save UTF-8. Run Publish validation before pushing. Editing JSON directly and pushing manually bypasses the publishing guardrails.

Cards show one category, one subcategory and up to two free tags. Free tags may be Vietnamese text; chip URLs normalize accents (`gấp gọn` becomes `gap-gon`). Search is accent-insensitive and checks published names/titles and tags across all types. URL filters combine with AND. Card chips go to `category.html`; Reels/Guides filter bars retain their own page. “Tất cả” resets subcategory/tag within the selected category; “Xóa bộ lọc” clears everything.

## Extend taxonomy

Edit `data/taxonomy.json`. Add a category object with unique lowercase hyphenated `slug`, Vietnamese `label`, optional display `name` (e.g. Tech), `description`, and `subcategories` array. Each subcategory has unique `slug` within that category and a Vietnamese `label`. Add subcategories to an existing array the same way. The client reads this taxonomy for cards/chips/filter bars; Publish refreshes the static navigation. No code mapping is needed. Unknown slugs cause console warnings in the client and block publishing.

## GitHub Pages deployment

1. Create a **public** repository and push the repository contents to `main`.
2. Go to **Settings > Pages > Build and deployment > Source > Deploy from a branch**.
3. Select **main**, **/(root)**, then Save.
4. Keep `.nojekyll` in the root. No package install or build command is needed.
5. Set `baseUrl` to the actual Pages URL, including `/haymint/` for a project repository, then run Publish.

Official source: [GitHub publishing source documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).

## Connect a custom domain later

1. Buy the domain only when ready. Verify ownership in GitHub and add the domain in repository **Settings > Pages > Custom domain** before changing DNS.
2. For branch publishing, GitHub creates a root `CNAME` file containing just your chosen hostname, e.g. `haymint.com` (no protocol/path). Pull that commit before local edits. Keep the file in your repo.
3. For an apex domain, use your DNS provider's ALIAS/ANAME to your account's Pages hostname, or the four GitHub Pages A records: `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`. Recheck the official documentation when configuring DNS. Remove conflicting defaults. Do not use wildcard records.
4. For `www`, create a DNS CNAME pointing to your account's Pages hostname, **without the repository name**. Configure both apex and www if desired.
5. After DNS/certificate provisioning, enable **Enforce HTTPS** in Pages settings.
6. Change `config.baseUrl` to the new HTTPS URL and run Publish. Internal paths need no edits. Only one hostname is configured as the primary Pages custom domain; an additional purchased domain needs its own redirect arrangement.

Official sources: [Managing custom domains](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site) and [HTTPS](https://docs.github.com/en/pages/getting-started-with-github-pages/securing-your-github-pages-site-with-https).

## Honesty, images and affiliate links

- Only your own photos and video thumbnails. Never images downloaded from Shopee seller pages. No Shopee logo.
- Original writing and original videos only. No reposted creators' videos.
- No testing/use claims, ratings, verdict labels, prices, carts, checkout or sale styling.
- Affiliate CTA is only “Xem trên Shopee”, mint with a generic bag icon. Affiliate links open with `target="_blank" rel="sponsored nofollow noopener"`.
- Empty affiliate URL means no shopping CTA. Video URL means a working external “Xem video” link, never `#`.
- One-line disclosure appears only in a visible section containing an actual affiliate link, including search and related products. The full footer and About explanation always remain.
- Do not create or publish affiliate links before your Shopee Affiliate account is approved. Register this website as a promotion channel in your Shopee Affiliate dashboard before using it for affiliate links. This is an owner checklist, not a guarantee of Shopee approval.
- Realistic AI content must be explicitly labeled at its point of use. No AI images are bundled.

## SEO and known static-host constraints

Every page has Vietnamese language, title, description, canonical, Open Graph, Twitter tags and inline SVG favicon. No Product/Review schema or ratings. Homepage-only Organization JSON-LD is refreshed by Publish and the client. No share image is invented: add your own original social image and corresponding OG/Twitter image metadata if you want image previews.

`guides/guide.html?slug=...` is a shared static template. The browser updates its title, description and canonical for the published guide. Crawlers that do not run JavaScript see the generic guide metadata; per-guide rich previews would require separate static HTML files or server rendering, neither of which is claimed here. Similarly, client-rendered content is not a substitute for server-rendered article HTML. Sitemap lists published guide URLs but cannot force indexing.

`404.html` is included and works when visited directly. Deep nonexistent paths on GitHub Pages can resolve relative assets differently; the live host's nested 404 behavior must be checked after deployment. No root-absolute fallback or account-specific URL is hardcoded.

## Verification

See `QUALITY-CHECKS.md` for actual executed checks and limitations. PowerShell execution on Windows 5.1/7 and authenticated Git push are **not claimed as tested** in this environment. Use the included disposable-copy smoke test in both shells before relying on the scripts:

```powershell
.\tools\Test-HayMintTools.ps1
```

The smoke test does not touch your live JSON, Git index or remote. It creates a temporary copy, exercises drafts and status changes, validates the empty site's SEO and confirms incomplete publishing is blocked, then deletes the temporary copy.
