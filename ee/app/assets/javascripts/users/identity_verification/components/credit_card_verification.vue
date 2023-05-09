<script>
import { GlButton, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import Zuora from 'ee/billings/components/zuora_simple.vue';
import { I18N_GENERIC_ERROR } from '../constants';

export const EVENT_CATEGORY = 'IdentityVerification::CreditCard';
export const EVENT_FAILED = 'failed_attempt';
export const EVENT_SUCCESS = 'success';

export default {
  components: {
    GlButton,
    GlIcon,
    GlLoadingIcon,
    Zuora,
  },
  mixins: [Tracking.mixin({ category: EVENT_CATEGORY })],
  inject: ['creditCard'],
  data() {
    return {
      currentUserId: this.creditCard.userId,
      formId: this.creditCard.formId,
      hasLoadError: false,
      isFormLoading: true,
      isCheckingForReuse: false,
      errorMessage: undefined,
    };
  },
  computed: {
    loadingStyle() {
      return { height: `${this.$options.zuoraFormHeight}px` };
    },
  },
  methods: {
    handleCheckForReuseResponse() {
      this.$emit('completed');
      this.track(EVENT_SUCCESS);
    },
    handleCheckForReuseError(error) {
      if (error.response.data?.message) {
        this.errorMessage = error.response.data.message;
      } else {
        createAlert({
          message: I18N_GENERIC_ERROR,
          captureError: true,
          error,
        });
      }
    },
    handleFormLoading(isFormLoading) {
      this.isFormLoading = isFormLoading;

      if (!isFormLoading && this.errorMessage) {
        this.alert = createAlert({ message: this.errorMessage });
        this.errorMessage = undefined;
      }
    },
    handleFormLoadError() {
      this.hasLoadError = true;
    },
    handleValidationError({ message }) {
      this.track(EVENT_FAILED, { property: message });
    },
    handleValidationSuccess() {
      this.isCheckingForReuse = true;

      axios
        .get(this.creditCard.verifyCreditCardPath)
        .then(this.handleCheckForReuseResponse)
        .catch(this.handleCheckForReuseError)
        .finally(() => {
          this.isCheckingForReuse = false;
        });
    },
    submit() {
      this.alert?.dismiss();
      this.$refs.zuora.submit();
    },
  },
  i18n: {
    formInfo: s__(
      'IdentityVerification|GitLab will not charge or store your payment information, it will only be used for verification.',
    ),
    formSubmit: s__('IdentityVerification|Verify payment method'),
  },
  zuoraFormHeight: 328,
};
</script>
<template>
  <div class="gl-display-flex gl-flex-direction-column">
    <div
      v-if="isCheckingForReuse"
      class="gl-display-flex gl-justify-content-center gl-align-items-center"
      :style="loadingStyle"
    >
      <gl-loading-icon size="lg" />
    </div>
    <zuora
      v-else
      ref="zuora"
      :current-user-id="currentUserId"
      :initial-height="$options.zuoraFormHeight"
      :payment-form-id="formId"
      @loading="handleFormLoading"
      @load-error="handleFormLoadError"
      @client-validation-error="handleValidationError"
      @server-validation-error="handleValidationError"
      @success="handleValidationSuccess"
    />

    <div class="gl-display-flex gl-mt-4 gl-mx-4 gl-text-secondary">
      <gl-icon class="gl-flex-shrink-0 gl-mt-2" name="information-o" :size="14" />
      <span class="gl-ml-2">{{ $options.i18n.formInfo }}</span>
    </div>

    <gl-button
      class="gl-mt-6"
      variant="confirm"
      type="submit"
      :disabled="isFormLoading || hasLoadError"
      @click="submit"
    >
      {{ $options.i18n.formSubmit }}
    </gl-button>
  </div>
</template>
