---
name: MacNewFile Design System
description: Unslopped macOS Sequoia native design system and web documentation standards.
colors:
  accent: "#2997ff"
  accent-fill: "#0071e3"
  accent-fill-hover: "#0077ed"
  semantic-green: "#30d158"
  semantic-red: "#ff453a"
  dark:
    bg-deep: "#0f0f10"
    bg-canvas: "#141415"
    bg-surface: "#1a1a1c"
    bg-surface-elevated: "#232326"
    border-hairline: "rgba(255, 255, 255, 0.08)"
    border-subtle: "rgba(255, 255, 255, 0.12)"
    border-strong: "rgba(255, 255, 255, 0.18)"
    text-primary: "#ededed"
    text-secondary: "#a1a1a6"
    text-muted: "#85858b"
  light:
    bg-deep: "#f2f2f4"
    bg-canvas: "#fafafa"
    bg-surface: "#ffffff"
    bg-surface-elevated: "#f4f4f5"
    border-hairline: "rgba(0, 0, 0, 0.07)"
    border-subtle: "rgba(0, 0, 0, 0.12)"
    border-strong: "rgba(0, 0, 0, 0.18)"
    text-primary: "#171717"
    text-secondary: "#525252"
    text-muted: "#737373"
typography:
  display:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif"
    fontSize: "clamp(2rem, 4.2vw, 3.2rem)"
    fontWeight: 600
    lineHeight: 1.14
    letterSpacing: "-0.03em"
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif"
    fontSize: "clamp(1.7rem, 3vw, 2.3rem)"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "-0.025em"
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif"
    fontSize: "1.5rem"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "-0.02em"
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.55
  body-sm:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.55
  mono:
    fontFamily: "'SF Mono', Menlo, Monaco, monospace"
    fontSize: "12.5px"
    fontWeight: 400
    lineHeight: 1.5
geometry:
  radius-sm: "6px"
  radius-md: "8px"
  radius-lg: "12px"
  radius-xl: "16px"
spacing-scale:
  - 4px
  - 8px
  - 12px
  - 16px
  - 20px
  - 24px
  - 32px
  - 40px
  - 48px
  - 64px
  - 80px
  - 96px
  - 128px
---

# Design System & Unslopping Principles

## 1. Character & Aesthetic
MacNewFile embodies calm, exact macOS utility craft. The interface avoids generic web landing page tropes (gradient blobs, rainbow charts, glowing text, excessive emoji badges) in favor of authentic Cupertino desktop fidelity:
- **Quiet Chrome**: Header, navigation, and controls remain understated so content and screenshots carry the visual focus.
- **Physical Depth**: Subtle hairline borders (`rgba(255, 255, 255, 0.08)`) and soft physical window shadows rather than zero-offset chromatic glows.
- **Authentic Framing**: Product screenshots sit inside authentic macOS window chrome complete with traffic light controls.

## 2. Color Ramp
- **Graphite Neutral Ramps**: Dark mode uses `#141415` canvas with `#1a1a1c` surface and `#232326` raised elements. Light mode uses `#fafafa` canvas with `#ffffff` card surfaces.
- **Three Text Roles**: `text-primary` for titles and active text, `text-secondary` for body copy, and `text-muted` for metadata and captions.
- **Single Accent**: Apple Blue (`#0071e3` / `#2997ff`) used with restraint on primary calls to action, active selections, and key indicators.

## 3. Typography & Sentence Case
- System typeface stack (`SF Pro Display`, `SF Pro Text`, `SF Mono`).
- Strict sentence case across all headings, labels, and table headers. No all-caps tracked labels.
- Keycaps rendered via `<kbd>` with subtle inset bevel and monospaced font.

## 4. Spacing & Nested Radius
- Strictly adheres to a 4px grid.
- Nested radius rule: Inner radius equals outer radius minus container padding, never dipping below 4px.
  - Windows: 16px
  - Cards & containers: 12px
  - Controls & buttons: 8px
  - Inner tags & pills: 6px

## 5. Responsive Standards
- **Desktop (1080px+)**: Fluid horizontal layout with 2-column feature rows and 3-column setup grid.
- **Tablet (860px and below)**: Navigation collapses into accessible mobile drawer; feature rows and onboarding steps stack vertically.
- **Mobile (480px and below)**: Action buttons expand to full width; table wrappers provide smooth horizontal scroll without viewport clipping.
