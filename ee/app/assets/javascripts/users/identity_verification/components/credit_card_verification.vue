<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import Zuora from 'ee/billings/components/zuora_simple.vue';
import { I18N_CC_FORM_SUBMIT, I18N_CC_FORM_INFO } from '../constants';

export default {
  components: {
    GlButton,
    GlIcon,
    Zuora,
  },
  inject: ['creditCardCompleted', 'creditCardFormId'],
  data() {
    return {
      formId: this.creditCardFormId,
      isVerified: this.creditCardCompleted,
      isLoading: true,
    };
  },
  computed: {
    currentUserId() {
      return window.gon.current_user_id;
    },
  },
  methods: {
    updateIsLoading(isLoading) {
      this.isLoading = isLoading;
    },
    onVerified() {
      this.$emit('verified');
      this.isVerified = true;
    },
    submit() {
      this.$refs.zuora.submit();
    },
  },
  I18N_CC_FORM_SUBMIT,
  I18N_CC_FORM_INFO,
};
</script>
<template>
  <div v-if="!isVerified" class="gl-display-flex gl-flex-direction-column gl-p-4">
    <zuora
      ref="zuora"
      :current-user-id="currentUserId"
      :initial-height="328"
      :payment-form-id="formId"
      @success="onVerified"
      @loading="updateIsLoading"
    />
    <div class="gl-display-flex gl-mt-4 gl-mx-4 gl-text-secondary">
      <gl-icon class="gl-flex-shrink-0 gl-mt-2" name="information-o" :size="14" />
      <span class="gl-ml-2">{{ $options.I18N_CC_FORM_INFO }}</span>
    </div>
    <gl-button
      class="gl-mt-6"
      variant="confirm"
      type="submit"
      :disabled="isLoading"
      @click="submit"
    >
      {{ $options.I18N_CC_FORM_SUBMIT }}
    </gl-button>
  </div>
</template>
