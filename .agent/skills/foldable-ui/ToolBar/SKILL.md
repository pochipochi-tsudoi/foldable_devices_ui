---
name: foldable-ui-tool-bar
description: >-
  Usage and implementation guide for ToolBar in foldable_devices_ui. Use when
  publishing AppBar actions (IconButton, BackButton, etc.) to the native iPhone
  Duo UIKit toolbar while preserving standard Flutter widgets on other platforms.
---

# ToolBar

Source: [`lib/src/widgets/app_action.dart`](../../../../lib/src/widgets/app_action.dart)

`ToolBar` moves supported Flutter controls into the native iOS UIKit toolbar when running on iPhone Duo inside [`DuoSafeArea`](../DuoSafeArea/SKILL.md). On all other platforms, the controls remain in their original Flutter layout slots.

---

## Constructor & Parameters

```dart
const ToolBar({
  Key? key,
  required List<Widget> child,
})
```

- **`child`** (`List<Widget>`, required): Controls to publish to the iPhone Duo toolbar, in display order.

---

## Supported Children & Roles

| Flutter Widget | Icon Requirement | Inferred `AppActionRole` | Priority | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `BackButton` | Built-in (`Icons.arrow_back_ios_new`) | `AppActionRole.back` | `100` | Only registered when `onPressed != null \|\| canPop` |
| `FloatingActionButton` | `child.child is Icon` | `AppActionRole.primary` | `80` | Consolidated into the single native toolbar group |
| `BottomNavigationBar` | Every item's `icon` & `activeIcon` is `Icon` | `AppActionRole.destination` | `70` | Publishes items as native toolbar destinations |
| `NavigationBar` | Every `NavigationDestination`'s `icon` & `selectedIcon` is `Icon` | `AppActionRole.destination` | `70` | Publishes destinations as native toolbar items |
| `IconButton` | `child.icon is Icon` | `AppActionRole.action` | `50` | Secondary toolbar action |

Any unsupported widget (or widget whose icon is not an `Icon`) is kept in Flutter and rendered in place.

---

## Platform & Apple HIG Behavior

1. **iPhone Duo (`isIphoneDuo == true`, both open and closed states)**:
   - Rasterizes each `Icon` widget into PNG bytes using the current `IconTheme`, `Theme.colorScheme.onSurface`, `Directionality`, `TextScaler`, and `devicePixelRatio` (never guesses or substitutes SF Symbols).
   - **Apple HIG Grouping**:
     - If there is **1** secondary action (`AppActionRole.action`) on the active route, it is displayed directly in the native toolbar capsule.
     - If there are **2 or more** secondary actions (`AppActionRole.action`) on the active route (even across multiple `ToolBar` widgets), [`DuoSafeArea`](../DuoSafeArea/SKILL.md) automatically groups them into a single `More` (`Icons.more_horiz`) button backed by a native iOS pull-down `UIMenu`.
   - Renders `SizedBox.shrink()` in the Flutter tree for all supported children.
2. **Other Platforms (Android Foldables, Tablets, Standard iOS/Android Phones)**:
   - Renders `child` directly in Flutter (`SizedBox.shrink()` if empty, the single widget if `child.length == 1`, or `Row(mainAxisSize: MainAxisSize.min, children: child)` if multiple).

---

## Usage Example

```dart
AppBar(
  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
  title: Text(widget.title),
  actions: [
    ToolBar(
      child: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'Full bleed demo',
          onPressed: () {
            Navigator.push(
              context,
              DuoSafeArea.route(
                builder: (context) => const NonSafeAreaScreen(),
              ),
            );
          },
        ),
      ],
    ),
    if (!widget.isBigScreen)
      ToolBar(
        child: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Information',
            onPressed: () {
              Navigator.push(
                context,
                DuoSafeArea.route(
                  builder: (context) => NextScreen(
                    width: widget.width,
                    isBigScreen: widget.isBigScreen,
                  ),
                ),
              );
            },
          ),
        ],
      ),
  ],
)
```
