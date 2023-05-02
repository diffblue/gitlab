<script>
import { SUPER_SIDEBAR_PEEK_OPEN_DELAY, SUPER_SIDEBAR_PEEK_CLOSE_DELAY } from '../constants';

export const STATE_CLOSED = 'closed';
export const STATE_WILL_OPEN = 'will-open';
export const STATE_OPEN = 'open';
export const STATE_WILL_CLOSE = 'will-close';

export const X_NEAR_WINDOW_EDGE = 8;

// Note: if the sidebar width changes (in CSS) this will also need to be
// updated. This might also be problematic if a descendant of the sidebar
// overflows, such that putting the cursor over that overflowed content would
// cause this to enter the STATE_WILL_CLOSE state, which would be annoying.
//
// Possible fixes:
//
// - Measure the sidebar in `mounted`. This assumes the sidebar will be
//   rendered in the document, which may not always be true.
// - Provide a way to "force" the STATUS_OPEN state by connecting
//   `mouseenter`/`mouseleave` events in the parent. These events may fire
//   reliably if the cursor is not moving while the sidebar is transitioning.
export const X_SIDEBAR_EDGE = 256;
export const X_AWAY_FROM_SIDEBAR = 2 * X_SIDEBAR_EDGE;

export default {
  name: 'SidebarPeek',
  created() {
    // Nothing needs to observe these properties, so they are not reactive.
    this.state = null;
    this.openTimer = null;
    this.closeTimer = null;
  },
  mounted() {
    document.addEventListener('mousemove', this.onMouseMove);
    this.changeState(STATE_CLOSED);
  },
  beforeDestroy() {
    document.removeEventListener('mousemove', this.onMouseMove);
    this.clearTimers();
  },
  methods: {
    /**
     * Callback for document-wide mousemove events.
     *
     * Since mousemove events can fire frequently, it's important for this to
     * do as little work as possible.
     *
     * When mousemove events fire within one of the defined regions, this ends
     * up being a no-op. Only when the cursor moves from one region to another
     * does this do any work: it sets a non-reactive instance property, maybe
     * cancels/starts timers, and emits an event.
     *
     * @params {MouseEvent} event
     */
    onMouseMove({ clientX }) {
      if (this.state === STATE_CLOSED) {
        if (clientX < X_NEAR_WINDOW_EDGE) {
          this.willOpen();
        }
      } else if (this.state === STATE_WILL_OPEN) {
        if (clientX >= X_NEAR_WINDOW_EDGE) {
          this.close();
        }
      } else if (this.state === STATE_OPEN) {
        if (clientX >= X_AWAY_FROM_SIDEBAR) {
          this.close();
        } else if (clientX >= X_SIDEBAR_EDGE) {
          this.willClose();
        }
      } else if (this.state === STATE_WILL_CLOSE) {
        if (clientX >= X_AWAY_FROM_SIDEBAR) {
          this.close();
        } else if (clientX < X_SIDEBAR_EDGE) {
          this.open();
        }
      }
    },
    willClose() {
      this.changeState(STATE_WILL_CLOSE);
      this.closeTimer = setTimeout(this.close, SUPER_SIDEBAR_PEEK_CLOSE_DELAY);
    },
    willOpen() {
      this.changeState(STATE_WILL_OPEN);
      this.openTimer = setTimeout(this.open, SUPER_SIDEBAR_PEEK_OPEN_DELAY);
    },
    open() {
      this.clearTimers();
      this.changeState(STATE_OPEN);
    },
    close() {
      this.clearTimers();
      this.changeState(STATE_CLOSED);
    },
    clearTimers() {
      clearTimeout(this.closeTimer);
      clearTimeout(this.openTimer);
    },
    changeState(state) {
      if (this.state === state) return;

      this.state = state;
      this.$emit('change', state);
    },
  },
  render() {
    return null;
  },
};
</script>
