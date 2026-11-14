---
name: MacNewFile Enhanced Design System
description: Native macOS Sequoia glassmorphism, SF typography, and Apple Human Interface Guidelines fidelity.
colors:
  primary: "#0071e3"
  primary-hover: "#0077ed"
  primary-active: "#0062c4"
  accent-green: "#34c759"
  accent-orange: "#ff9f0a"
  accent-red: "#ff453a"
  text-primary: "#f5f5f7"
  text-secondary: "#c2c2c7"
  text-tertiary: "#98989d"
  text-accent: "#47a3ff"
  term-bg: "#0d1117"
  term-header: "#161b22"
  term-text: "#c9d1d9"
  bg-canvas: "#090a0f"
  bg-subtle: "#11131a"
  bg-surface: "rgba(22, 24, 34, 0.72)"
  bg-surface-elevated: "rgba(30, 34, 48, 0.88)"
  border-subtle: "rgba(255, 255, 255, 0.08)"
  border-glass: "rgba(255, 255, 255, 0.14)"
typography:
  display:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif"
    fontSize: "clamp(2.6rem, 5.5vw, 4.4rem)"
    fontWeight: 800
    lineHeight: 1.08
    letterSpacing: "-0.04em"
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif"
    fontSize: "clamp(2.2rem, 4vw, 3rem)"
    fontWeight: 800
    lineHeight: 1.15
    letterSpacing: "-0.03em"
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif"
    fontSize: "1.4rem"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.02em"
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "normal"
  body-sm:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: "normal"
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: "normal"
  label-sm:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif"
    fontSize: "13px"
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: "normal"
  caption:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: 1.2
    letterSpacing: "normal"
  badge:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif"
    fontSize: "11px"
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "0.04em"
  mono:
    fontFamily: "'SF Mono', Menlo, Monaco, monospace"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: "normal"
rounded:
  sm: "6px"
  control: "8px"
  panel: "10px"
  card: "12px"
  card-lg: "14px"
  window: "16px"
  pill: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "36px"
  xxl: "48px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#ffffff"
    rounded: "{rounded.control}"
    padding: "12px 24px"
  button-primary-hover:
    backgroundColor: "{colors.primary-hover}"
---

# Design System

## Overview
MacNewFile Enhanced embodies modern macOS Sequoia desktop craft on the web. It avoids generic marketing landing page cliches (gradient blobs, glowing purple text, oversized fake metric cards) and instead delivers an authentic, tactile Apple computing interface. The surface serves both as an authoritative product showcase and a fully functional interactive simulator of the macOS Finder and Quick Look experience.

## Colors
- **Canvas (`#0b0c10`)**: Deep matte ground providing high-contrast backdrop for translucent panels.
- **Glass Surfaces (`rgba(22, 24, 33, 0.75)`)**: Sequoia-grade frosted glass with heavy backdrop blur (`blur(36px) saturate(180%)`).
- **Apple Blue (`#0071e3` / `#47a3ff`)**: Primary accent for controls and high-contrast link text meeting WCAG AA requirements (> 4.5:1).
- **Semantic Accents**: Authentic macOS system traffic light red (`#ff5f56`), yellow (`#ffbd2e`), green (`#27c93f`), and success green (`#34c759`).

## Typography
- **Display & Headings**: Apple San Francisco Pro Display with tight negative letter tracking (`-0.035em`) and balanced line wrapping.
- **Body & UI**: San Francisco Pro Text with optimal 65–75ch measure for reading clarity.
- **Code & Terminals**: SF Mono and monospace stacks for code snippets, gutters, status bars, and CLI commands.

## Layout
- **Fixed Top Menu Bar**: Sticky macOS Sequoia-style menu bar with live clock, status badge, and theme switcher.
- **Container Architecture**: Central responsive grid bounded at 1240px with generous vertical rhythm (60–80px between major sections).
- **Responsive Scalability**: Fluid breakpoints from desktop (1440px) down to mobile (390px) with graceful sidebar collapse.

## Elevation & Depth
- **Window Shadows**: Deep physical offset diffusion shadows (`0 32px 80px -16px rgba(0, 0, 0, 0.75)`).
- **Inner Specular Highlights**: Subtle 1px inner top border (`inset 0 1px 0 rgba(255, 255, 255, 0.16)`) mimicking the physical bevel of glass.
- **Zero Halos**: Strictly avoids artificial zero-offset colored glow halos in favor of realistic lighting and depth.

## Shapes
- **Corner Radii**: 14px for major windows and modals, 10px for panels and cards, 8px for buttons and inputs, and 9999px for pills and tags.
- **Precision Inset**: All containers maintain at least 12–16px inner padding to prevent text crowding.

## Components
- **Finder Window**: Faithful macOS Finder replica with active traffic lights, sidebar, canvas grid, and selection states.
- **Context Menu**: Native right-click menu with hierarchy, dividers, and nested flyout submenus.
- **Quick Editor**: Floating translucent editor dialog with line number gutter, multi-document tab bar, and syntax typography.
- **Terminal Simulator**: Authentic dark command window previewing instant directory jump integration.

## Do's and Don'ts
- **DO**: Maintain strict WCAG AA contrast compliance (minimum 4.5:1 for body and secondary text).
- **DO**: Use smooth exponential ease-out motion (`cubic-bezier(0.16, 1, 0.3, 1)`) for all interactive elements.
- **DON'T**: Use zero-offset chromatic glows, gradient text, or neon outlines.
- **DON'T**: Nest cards inside cards; use spacing, dividers, and subtle typography hierarchy instead.
