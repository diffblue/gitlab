/**
 * @module source_editor_instance
 */

/**
 * A Source Editor Extension definition
 * @typedef {Object} SourceEditorExtensionDefinition
 * @property {Object} definition
 * @property {Object} setupOptions
 */

/**
 * A Source Editor Extension
 * @typedef {Object} SourceEditorExtension
 * @property {Object} obj
 * @property {Object} api
 */

import { isEqual } from 'lodash';
import { editor as monacoEditor } from 'monaco-editor';
import { getBlobLanguage } from '~/editor/utils';
import { logError } from '~/lib/logger';
import { sprintf } from '~/locale';
import EditorExtension from './source_editor_extension';
import {
  EDITOR_EXTENSION_DEFINITION_TYPE_ERROR,
  EDITOR_EXTENSION_NAMING_CONFLICT_ERROR,
  EDITOR_EXTENSION_NO_DEFINITION_ERROR,
  EDITOR_EXTENSION_NOT_REGISTERED_ERROR,
  EDITOR_EXTENSION_NOT_SPECIFIED_FOR_UNUSE_ERROR,
  EDITOR_EXTENSION_STORE_IS_MISSING_ERROR,
} from './constants';

const utils = {
  removeExtFromMethod: (method, extensionName, container) => {
    if (!container) {
      return;
    }
    if (Object.prototype.hasOwnProperty.call(container, method)) {
      // eslint-disable-next-line no-param-reassign
      delete container[method];
    }
  },

  getStoredExtension: (extensionsStore, name) => {
    if (!extensionsStore) {
      logError(EDITOR_EXTENSION_STORE_IS_MISSING_ERROR);
      return undefined;
    }
    return extensionsStore.get(name);
  },
};

/** Class representing a Source Editor Instance */
export default class EditorInstance {
  constructor(rootInstance = {}, extensionsStore = new Map()) {
    /** The methods provided by extensions. */
    this.methods = {};

    const seInstance = this;
    const getHandler = {
      get(target, prop, receiver) {
        const methodExtension =
          Object.prototype.hasOwnProperty.call(seInstance.methods, prop) &&
          seInstance.methods[prop];
        if (methodExtension) {
          const extension = extensionsStore.get(methodExtension);

          return (...args) => {
            return extension.api[prop].call(seInstance, ...args, receiver);
          };
        }
        return seInstance[prop]
          ? Reflect.get(seInstance, prop, receiver)
          : Reflect.get(target, prop, receiver);
      },
      set(target, prop, value) {
        Object.assign(seInstance, {
          [prop]: value,
        });
        return true;
      },
    };
    const instProxy = new Proxy(rootInstance, getHandler);

    /**
     * Main entry point to apply an extension to the instance
     * @param {SourceEditorExtensionDefinition}
     */
    this.use = EditorInstance.useUnuse.bind(instProxy, extensionsStore, this.useExtension);

    /**
     * Main entry point to un-use an extension and remove it from the instance
     * @param {SourceEditorExtension}
     */
    this.unuse = EditorInstance.useUnuse.bind(instProxy, extensionsStore, this.unuseExtension);

    return instProxy;
  }

  static useUnuse(extensionsStore, fn, extensions) {
    if (Array.isArray(extensions)) {
      if (!extensions.length) {
        return fn.call(this, extensionsStore, undefined);
      }
      const exts = new Array(extensions.length);
      extensions.forEach((ext, i) => {
        exts[i] = fn.call(this, extensionsStore, ext);
      });
      return exts;
    }
    return fn.call(this, extensionsStore, extensions);
  }

  //
  // REGISTERING NEW EXTENSION
  //
  useExtension(extensionsStore, extensionDefinition = {}) {
    const { definition } = extensionDefinition;
    if (!definition) {
      throw new Error(EDITOR_EXTENSION_NO_DEFINITION_ERROR);
    }
    if (typeof definition !== 'function') {
      throw new Error(EDITOR_EXTENSION_DEFINITION_TYPE_ERROR);
    }

    // Existing Extension Path
    const existingExt = utils.getStoredExtension(extensionsStore, definition.name);
    if (existingExt) {
      if (isEqual(extensionDefinition.setupOptions, existingExt.setupOptions)) {
        return existingExt;
      }
      this.unuseExtension(extensionsStore, existingExt);
    }

    // New Extension Path
    const extension = new EditorExtension(extensionDefinition);
    const { name, setupOptions, obj: extensionObj } = extension;
    if (extensionObj.onSetup) {
      extensionObj.onSetup(setupOptions, this);
    }
    if (extensionsStore) {
      this.registerExtension(name, extension, extensionsStore);
    }
    this.registerExtensionMethods(name, extension);
    return extension;
  }

  registerExtension(name, extension, extensionsStore) {
    const hasExtensionRegistered =
      extensionsStore.has(name) &&
      isEqual(extension.setupOptions, extensionsStore.get(name).setupOptions);
    if (hasExtensionRegistered) {
      return;
    }
    extensionsStore.set(name, extension);
    const { obj: extensionObj } = extension;
    if (extensionObj.onUse) {
      extensionObj.onUse(this);
    }
  }

  registerExtensionMethods(name, extension) {
    const { api } = extension;

    if (!api) {
      return;
    }

    Object.keys(api).forEach((prop) => {
      if (this[prop]) {
        logError(sprintf(EDITOR_EXTENSION_NAMING_CONFLICT_ERROR, { prop }));
      } else {
        this.methods[prop] = name;
      }
    }, this);
  }

  //
  // UNREGISTERING AN EXTENSION
  //
  unuseExtension(extensionsStore, extension) {
    if (!extension) {
      throw new Error(EDITOR_EXTENSION_NOT_SPECIFIED_FOR_UNUSE_ERROR);
    }
    const { name } = extension;
    const existingExt = utils.getStoredExtension(extensionsStore, name);
    if (!existingExt) {
      throw new Error(sprintf(EDITOR_EXTENSION_NOT_REGISTERED_ERROR, { name }));
    }
    const { obj: extensionObj } = existingExt;
    if (extensionObj.onBeforeUnuse) {
      extensionObj.onBeforeUnuse(this);
    }
    this.unregisterExtensionMethods(name, existingExt);
    if (extensionObj.onUnuse) {
      extensionObj.onUnuse(this);
    }
  }

  unregisterExtensionMethods(name, extension) {
    const { api } = extension;
    if (!api) {
      return;
    }
    Object.keys(api).forEach((method) => {
      utils.removeExtFromMethod(method, name, this.methods);
    });
  }

  /**
   * PUBLIC API OF AN INSTANCE
   */

  /**
   * Updates model language based on the path
   * @param {String} path - blob path
   */
  updateModelLanguage(path) {
    const lang = getBlobLanguage(path);
    const model = this.getModel();
    // return monacoEditor.setModelLanguage(model, lang);
    monacoEditor.setModelLanguage(model, lang);
  }

  /**
   * Get the methods returned by extensions.
   * @returns {Array}
   */
  get extensionsAPI() {
    return Object.keys(this.methods);
  }
}
