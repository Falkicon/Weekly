# Spacing System

FenUI uses a systematic approach to spacing based on **Margin** and **Padding** tokens. This ensures consistent alignment across all components and prevents common UI issues like "background bleeding" or "transparent gaps".

## Mental Model: Margin vs. Padding

FenUI differentiates between spacing *outside* a container and spacing *inside* a container.

### 1. Margin (External Spacing)
Margins control the distance between a component and its parent or neighbors.
- **`marginPanel` (12px)**: Standard gap between a Panel's border and its primary inner containers (Insets, Grids).
- **`marginContainer` (8px)**: Standard gap between two adjacent containers (e.g., side-by-side cards).

### 2. Inset (Internal Spacing)
Insets control the distance from a component's edge to its internal content.
- **`insetContent` (8px)**: Standard padding within a container (e.g., text to edge distance).

---

## Systematic Application

### Panels
Panels use the `marginPanel` token to position their content slots. This ensures that content is perfectly aligned with the Blizzard "metal" border art.

### Insets and ScrollPanels
These convenience containers automatically apply `marginPanel` when placed inside a Panel. They provide a dark background that sits cleanly within the Panel's border.

### Layout Primitive
The `Layout` component uses a small `DEFAULT_BG_INSET` (2px) by default when a border is applied. This prevents the background color from "poking out" behind chamfered corners without creating large transparent gaps.

---

## Spacing Tokens

| Token | Type | Value | Use Case |
|-------|------|-------|----------|
| `marginPanel` | Semantic | `12px` | Panel -> Content gap |
| `marginContainer` | Semantic | `8px` | Gap between siblings |
| `insetContent` | Semantic | `8px` | Content -> Border gap |
| `spacingPanel` | Legacy | `16px` | Old internal padding (deprecated) |

## Layout Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `headerHeight` | `24px` | Safe-zone for Panel header bar |
| `footerHeight` | `32px` | Safe-zone for Panel footer bar |
| `tabHeight` | `28px` | Standard height for top tabs |

---

## Best Practices

1. **Avoid Hardcoded Offsets**: Always use `FenUI:GetSpacing("marginPanel")` or `FenUI:GetLayout("headerHeight")` instead of numeric literals like `-35`.
2. **Edge-to-Edge Content**: If you need a background image to touch the border art exactly, set `backgroundInset = 0` in the Layout config.
3. **Internal Spacing**: Use the `padding` property on Layouts and Grids to control content flow, rather than manually positioning every child.
