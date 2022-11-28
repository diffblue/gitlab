<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import Zuora from 'ee/billings/components/zuora_simple.vue';

export const EVENT_CATEGORY = 'IdentityVerification::CreditCard';
export const EVENT_FAILED = 'failed_attempt';
export const EVENT_SUCCESS = 'success';

export default {
  components: {
    GlButton,
    GlIcon,
    Zuora,
  },
  mixins: [Tracking.mixin({ category: EVENT_CATEGORY })],
  inject: ['creditCard'],
  data() {
    return {
      currentUserId: this.creditCard.userId,
      formId: this.creditCard.formId,
      hasLoadError: false,
      isLoading: true,
    };
  },
  methods: {
    updateIsLoading(isLoading) {
      this.isLoading = isLoading;
    },
    onComplete() {
      this.$emit('completed');
      this.track(EVENT_SUCCESS);
    },
    onError({ message }) {
      this.track(EVENT_FAILED, { property: message });
    },
    submit() {
      this.$refs.zuora.submit();
    },
    handleLoadError() {
      this.hasLoadError = true;
    },
  },
  i18n: {
    formInfo: s__(
      'IdentityVerification|GitLab will not charge or store your payment information, it will only be used for verification.',
    ),
    formSubmit: s__('IdentityVerification|Verify payment method'),
  },
};
</script>
<template>
  <div class="gl-display-flex gl-flex-direction-column">
    <zuora
      ref="zuora"
      :current-user-id="currentUserId"
      :initial-height="328"
      :payment-form-id="formId"
      @success="onComplete"
      @server-validation-error="onError"
      @client-validation-error="onError"
      @loading="updateIsLoading"
      @load-error="handleLoadError"
    />
    <div class="gl-display-flex gl-mt-4 gl-mx-4 gl-text-secondary">
      <gl-icon class="gl-flex-shrink-0 gl-mt-2" name="information-o" :size="14" />
      <span class="gl-ml-2">{{ $options.i18n.formInfo }}</span>
    </div>
    <gl-button
      class="gl-mt-6"
      variant="confirm"
      type="submit"
      :disabled="isLoading || hasLoadError"
      @click="submit"
    >
      {{ $options.i18n.formSubmit }}
    </gl-button>
  </div>
</template>
