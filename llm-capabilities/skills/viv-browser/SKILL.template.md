---
name: viv-browser
description: See and verify a web app in a real browser while building or fixing UI. Use when the user reports a visual problem, asks for a visual review of a page or component, or when a UI change needs verification that tests cannot give.
---

Drive a browser with the `playwright-cli` command line tool. The tool needs one
global install: `npm install -g @playwright/cli@latest`. The browser binary
downloads on the first `open` command.

## The loop

1. Get the address of the dev server from the user. Start the dev server only
   with their consent. Never guess a port.
2. Open one named session: `playwright-cli -s=<project> open <url>`.
3. Run `playwright-cli snapshot`. The output holds the accessibility tree and a
   ref for each element.
4. Capture the pixels: `playwright-cli screenshot <ref> --filename=tmp/pi/<name>.png`.
   Omit `<ref>` for the full viewport.
5. Read the PNG with the read tool. Judge the rendered page, not the markup.
6. Change the code. Wait for the rebuild, then capture again to a new filename
   and compare.
7. Run `playwright-cli console` when the page misbehaves or after each failed
   capture.
8. Close the session when the work ends: `playwright-cli -s=<project> close`.

## Rules

- Keep one session name per project. Parallel agents then never share a browser.
- Save each capture under `tmp/pi/` at the project root. Never reuse a filename
  in one session.
- The user names a component: capture that element. The user names a page:
  capture the viewport.
- Pixels alone do not explain a bug: run `playwright-cli eval <function> <ref>`
  and read the computed styles and the bounding box.
- State shows under real input. Use `click`, `fill`, `press`, and `hover` for
  flows. Do not simulate events with JavaScript when a real input works.
- Stay headless by default. Use `open --browser=chrome` only for a page behind a
  sign-in, and tell the user that page data then reaches the model provider.
- Tests and accessibility tools do not see layout geometry. Only a capture of the
  rendered page sees it.
