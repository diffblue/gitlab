// This is the only file allowed to import directly from the package.
// eslint-disable-next-line no-restricted-imports
import Mousetrap from 'mousetrap';

const additionalStopCallbacks = [];
const originalStopCallback = Mousetrap.prototype.stopCallback;

Mousetrap.prototype.stopCallback = function customStopCallback(e, element, combo) {
  for (const callback of additionalStopCallbacks) {
    const returnValue = callback.call(this, e, element, combo);
    if (returnValue !== undefined) return returnValue;
  }

  return originalStopCallback.call(this, e, element, combo);
};

/**
 * Add a stop callback to Mousetrap.
 *
 * The callback should have the same signature as Mousetrap#stopCallback. See
 * https://craig.is/killing/mice#api.stopCallback.
 *
 * The one difference is that the callback should return `undefined` if it
 * has no opinion on whether the current key combo should be stopped or not,
 * and the next stop callback should be consulted instead. If a boolean is
 * returned, no other stop callbacks are called.
 *
 * @param {Function} stopCallback The additional stop callback function to
 *     add to the chain of stop callbacks.
 * @returns {undefined}
 */
export const addStopCallback = (stopCallback) => {
  // Unshift, since we want to iterate through them in reverse order, so that
  // the most recently added handler is called first, and the original
  // stopCallback method is called last.
  additionalStopCallbacks.unshift(stopCallback);
};

/**
 * Clear additionalStopCallbacks. Used only for tests.
 */
export const clearStopCallbacksForTests = () => {
  additionalStopCallbacks.length = 0;
};

export default Mousetrap;
