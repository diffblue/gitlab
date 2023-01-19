<script>
import { uniqueId } from 'lodash';
import { GlAlert } from '@gitlab/ui';
import { needsArkoseLabsChallenge } from 'ee/rest_api';
import { logError } from '~/lib/logger';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { loadingIconForLegacyJS } from '~/loading_icon_for_legacy_js';
import { __ } from '~/locale';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';
import { initArkoseLabsScript } from '../init_arkose_labs_script';

const LOADING_ICON = loadingIconForLegacyJS({ classes: ['gl-mr-2'] });

const MSG_ARKOSE_NEEDED = __('Complete verification to sign in.');
const MSG_ARKOSE_FAILURE_TITLE = __('Unable to verify the user');
const MSG_ARKOSE_FAILURE_BODY = __(
  'An error occurred when loading the user verification challenge. Refresh to try again.',
);

const ARKOSE_CONTAINER_CLASS = 'js-arkose-labs-container-';

const VERIFICATION_TOKEN_INPUT_NAME = 'arkose_labs_token';

export default {
  components: {
    DomElementListener,
    GlAlert,
  },
  props: {
    publicKey: {
      type: String,
      required: true,
    },
    domain: {
      type: String,
      required: true,
    },
    formSelector: {
      type: String,
      required: true,
    },
    usernameSelector: {
      type: String,
      required: true,
    },
    submitSelector: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      arkoseLabsIframeShown: false,
      showArkoseNeededError: false,
      showArkoseFailure: false,
      username: '',
      isLoading: false,
      arkoseInitialized: false,
      submitOnSuppress: false,
      arkoseToken: '',
      arkoseContainerClass: uniqueId(ARKOSE_CONTAINER_CLASS),
      arkoseChallengePassed: false,
      needsChallengeChecks: [],
    };
  },
  computed: {
    showErrorContainer() {
      return (this.arkoseLabsIframeShown && this.showArkoseNeededError) || this.showArkoseFailure;
    },
  },
  watch: {
    isLoading(val) {
      this.updateSubmitButtonLoading(val);
    },
  },
  mounted() {
    this.needsChallengeChecks.push(this.checkIfNeedsChallenge());
  },
  methods: {
    onArkoseLabsIframeShown() {
      this.arkoseLabsIframeShown = true;
    },
    hideErrors() {
      this.showArkoseNeededError = false;
      this.showArkoseFailure = false;
    },
    getUsernameValue() {
      return document.querySelector(this.usernameSelector)?.value || '';
    },
    onBlur() {
      this.needsChallengeChecks.push(this.checkIfNeedsChallenge());
    },
    onSubmit(e) {
      if (this.arkoseChallengePassed) {
        // If the challenge was solved already, proceed with the form's submission.
        return;
      }

      e.preventDefault();
      this.submitOnSuppress = true;
      if (!this.arkoseInitialized) {
        // If the challenge hasn't been initialized yet, we trigger a check now to make sure it
        // wasn't skipped by submitting the form without the username field ever losing the focus.
        this.checkAndSubmit(e.target);
      } else {
        // Otherwise, we show an error message as the form has been submitted without completing
        // the challenge.
        this.showArkoseNeededError = true;
      }
    },
    async checkAndSubmit(form) {
      this.needsChallengeChecks.push(this.checkIfNeedsChallenge());

      // Wait for all calls to checkIfNeedsChallenge to finish before deciding
      // that the user does not need to see the challenge then submitting the
      // form. This prevents the form from being submitted before ArkoseLabs has
      // been properly set up after a call to (API) needsArkoseLabsChallenge
      // (e.g. when the user uses a password manager auto-fill-and-submit
      // feature which triggers onBlur and onSubmit in quick succession).
      await Promise.all(this.needsChallengeChecks);

      if (!this.arkoseInitialized) {
        // If the challenge still hasn't been initialized, the user definitely doesn't need one and
        // we can proceed with the form's submission.
        form.submit();
      }
    },
    async checkIfNeedsChallenge() {
      const username = this.getUsernameValue();
      if (!username || username === this.username || this.arkoseInitialized) {
        return;
      }

      this.username = username;
      this.isLoading = true;

      try {
        const {
          data: { result },
        } = await needsArkoseLabsChallenge(this.username);
        if (result) {
          await this.initArkoseLabs();
        }
      } catch (e) {
        if (e.response?.status === HTTP_STATUS_NOT_FOUND) {
          // We ignore 404 errors as it just means the username does not exist.
        } else if (e.response?.status) {
          // If the request failed with any other error code, we initialize the challenge to make
          // sure it isn't being bypassed by purposefully making the endpoint fail.
          this.initArkoseLabs();
        } else {
          // For any other failure, we show the initialization error message.
          this.handleArkoseLabsFailure(e);
        }
      } finally {
        this.isLoading = false;
      }
    },
    async initArkoseLabs() {
      this.arkoseInitialized = true;

      const enforcement = await initArkoseLabsScript({
        publicKey: this.publicKey,
        domain: this.domain,
      });

      enforcement.setConfig({
        mode: 'inline',
        selector: `.${this.arkoseContainerClass}`,
        onShown: this.onArkoseLabsIframeShown,
        onCompleted: this.passArkoseLabsChallenge,
        onError: this.handleArkoseLabsFailure,
      });
    },
    passArkoseLabsChallenge(response) {
      this.arkoseChallengePassed = true;
      this.arkoseToken = response.token;
      this.hideErrors();

      if (this.submitOnSuppress && response.suppressed) {
        // If the challenge was suppressed following the form's submission, we need to proceed with
        // the submission.
        this.$nextTick(() => {
          document.querySelector(this.formSelector).submit();
        });
      }
    },
    handleArkoseLabsFailure(e) {
      logError('ArkoseLabs initialization error', e);
      this.showArkoseFailure = true;
    },
    updateSubmitButtonLoading(val) {
      const button = document.querySelector(this.submitSelector);

      if (val) {
        const label = __('Loading');
        // eslint-disable-next-line no-unsanitized/property
        button.innerHTML = `
          ${LOADING_ICON.outerHTML}
          ${label}
        `;
        button.setAttribute('disabled', true);
      } else {
        button.innerText = __('Sign in');
        button.removeAttribute('disabled');
      }
    },
  },
  MSG_ARKOSE_NEEDED,
  MSG_ARKOSE_FAILURE_TITLE,
  MSG_ARKOSE_FAILURE_BODY,
  VERIFICATION_TOKEN_INPUT_NAME,
};
</script>

<template>
  <div>
    <dom-element-listener :selector="usernameSelector" @blur="onBlur" />
    <dom-element-listener :selector="formSelector" @submit="onSubmit" />
    <input
      v-if="arkoseInitialized"
      :name="$options.VERIFICATION_TOKEN_INPUT_NAME"
      type="hidden"
      :value="arkoseToken"
    />
    <div
      v-show="arkoseLabsIframeShown"
      class="gl-display-flex gl-justify-content-center gl-mt-3 gl-mb-n3"
      :class="arkoseContainerClass"
      data-testid="arkose-labs-challenge"
    ></div>
    <div v-if="showErrorContainer" class="gl-mb-3 gl-px-5" data-testid="arkose-labs-error-message">
      <gl-alert
        v-if="showArkoseFailure"
        :title="$options.MSG_ARKOSE_FAILURE_TITLE"
        variant="danger"
        :dismissible="false"
      >
        {{ $options.MSG_ARKOSE_FAILURE_BODY }}
      </gl-alert>
      <span v-else-if="showArkoseNeededError" class="gl-text-red-500">
        {{ $options.MSG_ARKOSE_NEEDED }}
      </span>
    </div>
  </div>
</template>
