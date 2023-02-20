<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import { STEPS } from 'ee/subscriptions/constants';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';
import activeStepQuery from 'ee/vue_shared/purchase_flow/graphql/queries/active_step.query.graphql';
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
        this.$emit(PurchaseEvent.ERROR, { error });
      },
    },
  },
  computed: {
    ...mapState(['isConfirmingOrder']),
    ...mapGetters(['hasValidPriceDetails']),
    shouldDisableConfirmOrder() {
      return this.isConfirmingOrder || !this.hasValidPriceDetails;
    },
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
      :disabled="shouldDisableConfirmOrder"
      variant="confirm"
      category="primary"
      @click="confirmOrder"
    >
      <gl-loading-icon v-if="isConfirmingOrder" inline size="sm" />
      {{ isConfirmingOrder ? $options.i18n.confirming : $options.i18n.confirm }}
    </gl-button>
  </div>
</template>
