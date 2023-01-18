<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { STEPS } from 'ee/subscriptions/constants';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import activeStepQuery from 'ee/vue_shared/purchase_flow/graphql/queries/active_step.query.graphql';
import { createAlert } from '~/flash';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
  },
  data() {
    return {
      isActive: {},
    };
  },
  apollo: {
    isActive: {
      query: activeStepQuery,
      update: ({ activeStep }) => activeStep?.id === STEPS[3].id,
      error: (error) => {
        createAlert({ message: GENERAL_ERROR_MESSAGE, error, captureError: true });
      },
    },
  },
  computed: {
    ...mapState(['isConfirmingOrder']),
  },
  methods: {
    ...mapActions(['confirmOrder']),
  },
  i18n: {
    confirm: s__('Checkout|Confirm purchase'),
    confirming: s__('Checkout|Confirming...'),
  },
};
</script>
<template>
  <div v-if="isActive" class="full-width gl-mt-5 gl-mb-7">
    <gl-button
      :disabled="isConfirmingOrder"
      variant="confirm"
      category="primary"
      @click="confirmOrder"
    >
      <gl-loading-icon v-if="isConfirmingOrder" inline size="sm" />
      {{ isConfirmingOrder ? $options.i18n.confirming : $options.i18n.confirm }}
    </gl-button>
  </div>
</template>
