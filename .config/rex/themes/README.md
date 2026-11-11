# Rex themes

These Ghostty-format files preserve the Flexoki Light and Flexoki Dark palettes
exported from Rex, including ANSI colors, background, foreground, cursor, and
selection colors. Extended colors (16–255) use the standard xterm palette.

To import a theme, run one of these commands from the repository root:

```sh
rex do client.theme.import path="$PWD/.config/rex/themes/flexoki-light"
rex do client.theme.import path="$PWD/.config/rex/themes/flexoki-dark"
```

Importing also selects the theme. Rex copies imported themes into its macOS
preferences; these files are not live-linked. Re-import after editing a file.
