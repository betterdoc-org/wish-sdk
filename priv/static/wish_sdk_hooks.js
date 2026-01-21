/**
 * WishSdk LiveView Hooks (Optional)
 * 
 * Minimal JavaScript hooks for UI enhancements.
 * All API calls are handled server-side via Elixir/LiveView.
 * 
 * These hooks are OPTIONAL and only provide UI niceties like:
 * - Auto-scrolling during streaming
 * - Focus management
 * 
 * The SDK works perfectly fine without these hooks!
 */

const WishHooks = {
  // Optional: Auto-scroll to bottom when response updates
  WishResponseAutoScroll: {
    mounted() {
      this.pending = false;

      this.scrollContainer = this.findOverflowContainer(this.el);

      // If user scrolls (wheel), stop auto-scrolling for this hook instance
      this.onWheel = () => {
        this.pending = true;
      };
      (this.scrollContainer || this.el).addEventListener("wheel", this.onWheel, { passive: true });

      // Initial scroll (after mount)
      this.scrollToBottom();
    },

    updated() {
      // Only auto-scroll while streaming is active and user hasn't manually scrolled
      if (this.el.dataset.autoScroll !== "true") return;
      if (this.el.dataset.streaming !== "true") return;
      if (this.pending) return;

      this.scrollToBottom();
    },

    scrollToBottom() {
      const container = this.scrollContainer || this.el;

      // wait for layout
      requestAnimationFrame(() => {
        const max = container.scrollHeight - container.clientHeight;
        const before = container.scrollTop;
        container.scrollTop = max;
      });
    },

    findOverflowContainer(element) {
      let parent = element.parentElement;
      while (parent) {
        const overflowY = window.getComputedStyle(parent).overflowY;
        if (overflowY === "auto" || overflowY === "scroll") return parent;
        parent = parent.parentElement;
      }
      return element;
    },

    destroyed() {
      try {
        (this.scrollContainer || this.el).removeEventListener("wheel", this.onWheel);
      } catch (_) {}
    }
  },

  // Optional: Focus management for input fields
  WishPromptInput: {
    mounted() {
      if (this.el.dataset.autoFocus === "true") {
        this.el.focus();
      }
    }
  }
};

export default WishHooks;
