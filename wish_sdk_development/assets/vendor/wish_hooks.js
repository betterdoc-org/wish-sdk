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
      this.observer = new MutationObserver(() => {
        if (this.el.dataset.autoScroll === "true") {
          this.el.scrollTop = this.el.scrollHeight;
        }
      });
      
      this.observer.observe(this.el, {
        childList: true,
        subtree: true,
        characterData: true
      });
    },
    
    destroyed() {
      if (this.observer) {
        this.observer.disconnect();
      }
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
