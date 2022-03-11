import Vue from 'vue';
import { GlAlert } from '@gitlab/ui';
import { needsArkoseLabsChallenge } from 'ee/rest_api';
import { loadingIconForLegacyJS } from '~/loading_icon_for_legacy_js';
import { __ } from '~/locale';

const VERIFICATION_TOKEN_INPUT_NAME = 'arkose_labs_token';
const LOADING_ICON = loadingIconForLegacyJS({ classes: ['gl-mr-2'] });
const CHALLENGE_ERRORS_CONTAINER_CLASS = 'js-arkose-labs-error-message';

export class ArkoseLabs {
  constructor() {
    this.signInForm = document.querySelector('.js-sign-in-form');

    if (!this.signInForm) {
      return;
    }

    this.usernameField = this.signInForm.querySelector('.js-username-field');
    this.arkoseLabsChallengeContainer = this.signInForm.querySelector('.js-arkose-labs-challenge');
    this.signInButton = this.signInForm.querySelector('.js-sign-in-button');

    this.onUsernameFieldBlur = this.onUsernameFieldBlur.bind(this);
    this.onSignInFormSubmitted = this.onSignInFormSubmitted.bind(this);
    this.setConfig = this.setConfig.bind(this);
    this.passArkoseLabsChallenge = this.passArkoseLabsChallenge.bind(this);
    this.handleArkoseLabsFailure = this.handleArkoseLabsFailure.bind(this);

    this.publicKey = this.arkoseLabsChallengeContainer.dataset.apiKey;
    this.username = this.usernameField.value || '';
    this.arkoseLabsInitialized = false;
    this.arkoseLabsChallengePassed = false;

    window.setupArkoseLabsEnforcement = this.setConfig;

    this.attachEventListeners();

    if (this.username.length) {
      this.checkIfNeedsChallenge();
    }
  }

  attachEventListeners() {
    this.usernameField.addEventListener('blur', this.onUsernameFieldBlur);
    this.signInForm.addEventListener('submit', this.onSignInFormSubmitted);
  }

  detachEventListeners() {
    this.usernameField.removeEventListener('blur', this.onUsernameFieldBlur);
    this.signInForm.removeEventListener('submit', this.onSignInFormSubmitted);
  }

  onUsernameFieldBlur() {
    const { value } = this.usernameField;
    if (this.username !== this.usernameField.value) {
      this.username = value;
      this.checkIfNeedsChallenge();
    }
  }

  onSignInFormSubmitted(e) {
    if (!this.arkoseLabsInitialized || this.arkoseLabsChallengePassed) {
      return;
    }
    e.preventDefault();
    this.showArkoseLabsErrorMessage();
  }

  async checkIfNeedsChallenge() {
    if (this.arkoseLabsInitialized) {
      return;
    }

    this.setButtonLoadingState();

    try {
      const {
        data: { result },
      } = await needsArkoseLabsChallenge(this.username);

      if (result) {
        this.initArkoseLabsChallenge();
      }
    } catch {
      // API call failed, do not initialize Arkose challenge.
      // Button will be reset in `finally` block.
    } finally {
      this.resetButton();
    }
  }

  setButtonLoadingState() {
    const label = __('Loading');
    this.signInButton.innerHTML = `
      ${LOADING_ICON.outerHTML}
      ${label}
    `;
    this.signInButton.setAttribute('disabled', true);
  }

  resetButton() {
    this.signInButton.innerText = __('Sign in');
    this.signInButton.removeAttribute('disabled');
  }

  initArkoseLabsChallenge() {
    this.arkoseLabsInitialized = true;
    const tag = document.createElement('script');
    [
      ['type', 'text/javascript'],
      ['src', `https://client-api.arkoselabs.com/v2/${this.publicKey}/api.js`],
      ['nonce', true],
      ['async', true],
      ['defer', true],
      ['data-callback', 'setupArkoseLabsEnforcement'],
    ].forEach(([attr, value]) => {
      tag.setAttribute(attr, value);
    });
    document.head.appendChild(tag);

    const tokenInput = document.createElement('input');
    tokenInput.name = VERIFICATION_TOKEN_INPUT_NAME;
    tokenInput.setAttribute('type', 'hidden');
    this.tokenInput = tokenInput;
    this.signInForm.appendChild(tokenInput);
  }

  setConfig(enforcement) {
    enforcement.setConfig({
      mode: 'inline',
      selector: '.js-arkose-labs-challenge',

      onShown: () => {
        this.arkoseLabsChallengeContainer.classList.remove('gl-display-none!');
      },
      onCompleted: this.passArkoseLabsChallenge,
      onSuppress: this.passArkoseLabsChallenge,
      onError: this.handleArkoseLabsFailure,
    });
  }

  createArkoseLabsErrorMessageContainer() {
    if (!this.arkoseLabsErrorMessageContainer) {
      const arkoseLabsErrorMessageContainer = document.createElement('div');
      arkoseLabsErrorMessageContainer.className = `gl-mb-3 ${CHALLENGE_ERRORS_CONTAINER_CLASS}`;
      arkoseLabsErrorMessageContainer.setAttribute('data-testid', 'arkose-labs-error-message');
      this.arkoseLabsChallengeContainer.parentNode.insertBefore(
        arkoseLabsErrorMessageContainer,
        this.arkoseLabsChallengeContainer.nextSibling,
      );
      this.arkoseLabsErrorMessageContainer = arkoseLabsErrorMessageContainer;
    }
    this.arkoseLabsErrorMessageContainer.classList.remove('gl-display-none');
  }

  showArkoseLabsErrorMessage() {
    this.createArkoseLabsErrorMessageContainer();
    this.arkoseLabsErrorMessageContainer.innerHTML = `
      <span class="gl-text-red-500">
        ${__('Complete verification to sign in.')}
      </span>`;
  }

  hideArkoseLabsErrorMessage() {
    this.arkoseLabsErrorMessageContainer?.classList.add('gl-display-none');
  }

  passArkoseLabsChallenge(response) {
    this.arkoseLabsChallengePassed = true;
    this.tokenInput.value = response.token;
    this.hideArkoseLabsErrorMessage();
  }

  handleArkoseLabsFailure() {
    this.createArkoseLabsErrorMessageContainer();
    return new Vue({
      el: `.${CHALLENGE_ERRORS_CONTAINER_CLASS}`,
      components: { GlAlert },
      render(h) {
        return h(
          GlAlert,
          {
            props: {
              title: __('Unable to verify the user'),
              dismissible: false,
              variant: 'danger',
            },
            attrs: {
              'data-testid': 'arkose-labs-failure-alert',
            },
          },
          __(
            'An error occurred when loading the user verification challenge. Refresh to try again.',
          ),
        );
      },
    });
  }
}
