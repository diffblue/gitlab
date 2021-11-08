import { EDITOR_EXTENSION_DEFINITION_ERROR } from './constants';

export default class EditorExtension {
  constructor({ definition, setupOptions } = {}) {
    if (typeof definition !== 'function') {
      throw new Error(EDITOR_EXTENSION_DEFINITION_ERROR);
    }
    this.name = definition.name; // both class- and fn-based extensions have a name
    this.setupOptions = setupOptions;
    // eslint-disable-next-line new-cap
    this.obj = new definition();
  }

  get api() {
    return this.obj.provides();
  }

  /**
   * THE LIFE-CYCLE CALLBACKS
   */

  /**
   * Is called before the extension gets used by an instance,
   * Use `onSetup` to setup Monaco directly:
   * actions, keystrokes, update options, etc.
   * Is called only once before the extension gets registered
   *
   * @param { Object } [options]  The setupOptions object
   * @param { Object } [instance] The Source Editor instance
   */
  // eslint-disable-next-line class-methods-use-this,no-unused-vars
  onSetup(options, instance) {}

  /**
   * The first thing called after the extension is
   * registered and used by an instance.
   * Is called every time the extension is applied
   *
   * @param { Object } [instance] The Source Editor instance
   */
  // eslint-disable-next-line class-methods-use-this,no-unused-vars
  onUse(instance) {}

  /**
   * Is called before un-using an extension. Can be used for time-critical
   * actions like cleanup, reverting visual changes, and other user-facing
   * updates.
   *
   * @param { Object } [instance] The Source Editor instance
   */
  // eslint-disable-next-line class-methods-use-this,no-unused-vars
  onBeforeUnuse(instance) {}

  /**
   * Is called right after an extension is removed from an instance (un-used)
   * Can be used for non time-critical tasks like cleanup on the Monaco level
   * (removing actions, keystrokes, etc.).
   * onUnuse() will be executed during the browser's idle period
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window/requestIdleCallback)
   *
   * @param { Object } [instance] The Source Editor instance
   */
  // eslint-disable-next-line class-methods-use-this,no-unused-vars
  onUnuse(instance) {}
}
