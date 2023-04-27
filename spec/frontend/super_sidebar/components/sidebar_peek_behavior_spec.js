import { mount } from '@vue/test-utils';
import {
  SUPER_SIDEBAR_PEEK_OPEN_DELAY,
  SUPER_SIDEBAR_PEEK_CLOSE_DELAY,
} from '~/super_sidebar/constants';
import SidebarPeek, {
  X_NEAR_WINDOW_EDGE,
  X_SIDEBAR_EDGE,
  X_AWAY_FROM_SIDEBAR,
  STATE_CLOSED,
  STATE_WILL_OPEN,
  STATE_OPEN,
  STATE_WILL_CLOSE,
} from '~/super_sidebar/components/sidebar_peek_behavior.vue';

describe('SidebarPeek component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(SidebarPeek);
  };

  const moveMouse = (clientX) => {
    const event = new MouseEvent('mousemove', {
      clientX,
    });

    document.dispatchEvent(event);
  };

  const lastNChangeEvents = (n = 1) => wrapper.emitted('change').slice(-n).flat();

  beforeEach(() => {
    createComponent();
  });

  it('begins in the closed state', () => {
    expect(lastNChangeEvents(Infinity)).toEqual([STATE_CLOSED]);
  });

  it('does not emit duplicate events in a region', () => {
    moveMouse(0);
    moveMouse(1);
    moveMouse(2);

    expect(lastNChangeEvents(Infinity)).toEqual([STATE_CLOSED, STATE_WILL_OPEN]);
  });

  it('transitions to will-open when in peek region', () => {
    moveMouse(X_NEAR_WINDOW_EDGE);

    expect(lastNChangeEvents(1)).toEqual([STATE_CLOSED]);

    moveMouse(X_NEAR_WINDOW_EDGE - 1);

    expect(lastNChangeEvents(1)).toEqual([STATE_WILL_OPEN]);
  });

  it('transitions will-open -> open after delay', () => {
    moveMouse(0);
    jest.advanceTimersByTime(SUPER_SIDEBAR_PEEK_OPEN_DELAY - 1);

    expect(lastNChangeEvents(1)).toEqual([STATE_WILL_OPEN]);

    jest.advanceTimersByTime(1);

    expect(lastNChangeEvents(2)).toEqual([STATE_WILL_OPEN, STATE_OPEN]);
  });

  it('cancels transition will-open -> open if mouse out of peek region', () => {
    moveMouse(0);
    jest.advanceTimersByTime(SUPER_SIDEBAR_PEEK_OPEN_DELAY - 1);

    moveMouse(X_NEAR_WINDOW_EDGE);

    jest.runOnlyPendingTimers();

    expect(lastNChangeEvents(3)).toEqual([STATE_CLOSED, STATE_WILL_OPEN, STATE_CLOSED]);
  });

  it('transitions open -> will-close if mouse out of sidebar region', () => {
    moveMouse(0);
    jest.runOnlyPendingTimers();

    moveMouse(X_SIDEBAR_EDGE - 1);

    expect(lastNChangeEvents(1)).toEqual([STATE_OPEN]);

    moveMouse(X_SIDEBAR_EDGE);

    expect(lastNChangeEvents(2)).toEqual([STATE_OPEN, STATE_WILL_CLOSE]);
  });

  it('transitions will-close -> closed after delay', () => {
    moveMouse(0);
    jest.runOnlyPendingTimers();

    moveMouse(X_SIDEBAR_EDGE);
    jest.advanceTimersByTime(SUPER_SIDEBAR_PEEK_CLOSE_DELAY - 1);

    expect(lastNChangeEvents(1)).toEqual([STATE_WILL_CLOSE]);

    jest.advanceTimersByTime(1);

    expect(lastNChangeEvents(2)).toEqual([STATE_WILL_CLOSE, STATE_CLOSED]);
  });

  it('cancels transition will-close -> close if mouse move in sidebar region', () => {
    moveMouse(0);
    jest.runOnlyPendingTimers();

    moveMouse(X_SIDEBAR_EDGE);
    jest.advanceTimersByTime(SUPER_SIDEBAR_PEEK_CLOSE_DELAY - 1);

    expect(lastNChangeEvents(1)).toEqual([STATE_WILL_CLOSE]);

    moveMouse(X_SIDEBAR_EDGE - 1);
    jest.runOnlyPendingTimers();

    expect(lastNChangeEvents(3)).toEqual([STATE_OPEN, STATE_WILL_CLOSE, STATE_OPEN]);
  });

  it('immediately transitions open -> closed if mouse moves far away', () => {
    moveMouse(0);
    jest.runOnlyPendingTimers();

    moveMouse(X_AWAY_FROM_SIDEBAR);

    expect(lastNChangeEvents(2)).toEqual([STATE_OPEN, STATE_CLOSED]);
  });

  it('immediately transitions will-close -> closed if mouse moves far away', () => {
    moveMouse(0);
    jest.runOnlyPendingTimers();

    moveMouse(X_AWAY_FROM_SIDEBAR - 1);
    moveMouse(X_AWAY_FROM_SIDEBAR);

    expect(lastNChangeEvents(2)).toEqual([STATE_WILL_CLOSE, STATE_CLOSED]);
  });

  it('cleans up its mousemove listener before destroy', () => {
    moveMouse(0);
    jest.runOnlyPendingTimers();

    wrapper.destroy();
    moveMouse(X_AWAY_FROM_SIDEBAR);

    expect(lastNChangeEvents(1)).toEqual([STATE_OPEN]);
  });

  it('cleans up its timers before destroy', () => {
    moveMouse(0);

    wrapper.destroy();
    jest.runOnlyPendingTimers();

    expect(lastNChangeEvents(1)).toEqual([STATE_WILL_OPEN]);
  });
});
