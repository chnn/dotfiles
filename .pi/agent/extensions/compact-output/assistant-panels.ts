import { AssistantMessageComponent } from "@earendil-works/pi-coding-agent";
import type { Theme } from "@earendil-works/pi-coding-agent";
import { Box, type Component, Container, Markdown } from "@earendil-works/pi-tui";

const PATCH = Symbol.for("dotfiles.compact-output.assistant-panels");
type AssistantPrototype = typeof AssistantMessageComponent.prototype & {
  [PATCH]?: () => void;
};

class AssistantTextPanel extends Box {
  constructor(
    private readonly enabled: () => boolean,
    getTheme: () => Theme,
  ) {
    // Markdown already applies outputPad horizontally. Add only vertical padding.
    super(0, 1, (line) => getTheme().bg("customMessageBg", line));
  }

  render(width: number): string[] {
    // Existing transcript components must lose their decoration on unload as well.
    if (!this.enabled()) return this.children.flatMap((child) => child.render(width));
    return width > 0 ? super.render(width) : [];
  }
}

/**
 * Pi 1.1 has no assistant renderer registration API. This compatibility shim delegates
 * to its native updateContent, then wraps only direct Markdown children. Thinking is
 * inside MouseRegion components, and tool executions are separate transcript rows.
 * No message data or native Markdown behavior is changed.
 */
export function installAssistantPanels(getTheme: () => Theme): () => void {
  const prototype = AssistantMessageComponent.prototype as AssistantPrototype;
  prototype[PATCH]?.(); // Avoid stacked wrappers across reloads or duplicate loads.
  const original = prototype.updateContent;
  let enabled = true;

  const decorated: typeof original = function (
    this: AssistantMessageComponent,
    ...args: Parameters<typeof original>
  ) {
    original.apply(this, args);
    if (!enabled) return;
    // Use the public component tree; if Pi changes its layout, leave it untouched.
    for (const container of this.children) {
      if (!(container instanceof Container)) continue;
      const children: Component[] = [];
      let panel: AssistantTextPanel | undefined;
      for (const child of container.children) {
        if (child instanceof Markdown) {
          if (!panel) {
            panel = new AssistantTextPanel(() => enabled, getTheme);
            children.push(panel);
          }
          panel.addChild(child);
        } else {
          panel = undefined;
          children.push(child);
        }
      }
      container.clear();
      for (const child of children) container.addChild(child);
    }
  };

  const dispose = () => {
    enabled = false;
    if (prototype.updateContent === decorated) prototype.updateContent = original;
    if (prototype[PATCH] === dispose) delete prototype[PATCH];
  };
  prototype.updateContent = decorated;
  prototype[PATCH] = dispose;
  return dispose;
}
