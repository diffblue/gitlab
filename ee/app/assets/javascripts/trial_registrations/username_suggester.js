import { debounce } from 'lodash';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

const USERNAME_SUGGEST_DEBOUNCE_TIME = 300;

export default class UsernameSuggester {
  /**
   * Creates an instance of UsernameSuggester.
   * @param {string} targetElement target input element id for suggested username
   * @param {string[]} sourceElementsIds array of HTML input element ids used for generating username
   */
  constructor(targetElement, sourceElementsIds = []) {
    if (!targetElement) {
      throw new Error("Required argument 'targetElement' is missing");
    }

    this.usernameElement = document.getElementById(targetElement);

    if (!this.usernameElement) {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      throw new Error('The target element is missing.');
    }

    this.apiPath = this.usernameElement.dataset.apiPath;
    if (!this.apiPath) {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      throw new Error('The API path was not specified.');
    }

    this.sourceElements = sourceElementsIds
      .map((id) => document.getElementById(id))
      .filter(Boolean);
    this.isLoading = false;
    this.debouncedSuggestWrapper = debounce(
      this.suggestUsername.bind(this),
      USERNAME_SUGGEST_DEBOUNCE_TIME,
    );

    this.bindEvents();
    this.cleanupWrapper = this.cleanup.bind(this);
    window.addEventListener('beforeunload', this.cleanupWrapper);
  }

  bindEvents() {
    this.sourceElements.forEach((sourceElement) => {
      sourceElement.addEventListener('change', this.debouncedSuggestWrapper);
    });
  }

  suggestUsername() {
    if (this.isLoading) {
      return;
    }

    const name = this.joinSources();

    if (!name) {
      return;
    }

    axios
      .get(this.apiPath, { params: { name } })
      .then(({ data }) => {
        this.usernameElement.value = data.username;
      })
      .catch(() => {
        createFlash({
          message: __('An error occurred while generating a username. Please try again.'),
        });
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  /**
   * Joins values from HTML input elements to a string separated by `_` (underscore).
   */
  joinSources() {
    return this.sourceElements
      .map((el) => el.value)
      .filter(Boolean)
      .join('_');
  }

  cleanup() {
    window.removeEventListener('beforeunload', this.cleanupWrapper);

    this.sourceElements.forEach((sourceElement) =>
      sourceElement.removeEventListener('change', this.debouncedSuggestWrapper),
    );
  }
}
