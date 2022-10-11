<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import Zuora from 'ee/billings/components/zuora_simple.vue';
import { I18N_CC_VERIFICATION } from '../constants';

export default {
  components: {
    GlButton,
    GlIcon,
    Zuora,
  },
  inject: ['creditCard'],
  data() {
    return {
      currentUserId: this.creditCard.userId,
      formId: this.creditCard.formId,
      isLoading: true,
    };
  },
  methods: {
    updateIsLoading(isLoading) {
      this.isLoading = isLoading;
    },
    onComplete() {
      this.$emit('completed');
    },
    submit() {
      this.$refs.zuora.submit();
    },
  },
  i18n: I18N_CC_VERIFICATION,
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
      @loading="updateIsLoading"
    />
    <div class="gl-display-flex gl-mt-4 gl-mx-4 gl-text-secondary">
      <gl-icon class="gl-flex-shrink-0 gl-mt-2" name="information-o" :size="14" />
      <span class="gl-ml-2">{{ $options.i18n.form_info }}</span>
    </div>
    <gl-button
      class="gl-mt-6"
      variant="confirm"
      type="submit"
      :disabled="isLoading"
      @click="submit"
    >
      {{ $options.i18n.form_submit }}
    </gl-button>
  </div>
</template>
