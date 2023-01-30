<script>
import { GlCard } from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
import { sprintf, s__ } from '~/locale';
import { trackCheckout } from '~/google_tag_manager';
import SummaryDetails from 'jh_else_ee/subscriptions/new/components/order_summary/summary_details.vue';
import formattingMixins from '../formatting_mixins';
import PromoCodeInput from './promo_code_input.vue';

export default {
  components: {
    PromoCodeInput,
    SummaryDetails,
    GlCard,
  },
  mixins: [formattingMixins],
  computed: {
    ...mapState(['numberOfUsers', 'selectedPlan']),
    ...mapGetters([
      'selectedPlanText',
      'totalAmount',
      'name',
      'usersPresent',
      'isGroupSelected',
      'isSelectedGroupPresent',
      'isEligibleToUsePromoCode',
    ]),
    titleWithName() {
      return sprintf(this.$options.i18n.title, { name: this.name });
    },
  },
  mounted() {
    trackCheckout(this.selectedPlan, this.numberOfUsers);
  },
  i18n: {
    title: s__("Checkout|%{name}'s GitLab subscription"),
  },
};
</script>
<template>
  <gl-card
    v-if="!isGroupSelected || isSelectedGroupPresent"
    class="order-summary gl-display-flex gl-flex-direction-column gl-flex-grow-1"
  >
    <div class="gl-lg-display-none">
      <h4
        class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-font-lg gl-my-0"
      >
        <div class="gl-display-flex gl-align-items-center">
          <span class="gl-ml-2">{{ titleWithName }}</span>
        </div>
        <span class="gl-ml-3">{{ formatAmount(totalAmount, usersPresent) }}</span>
      </h4>
      <summary-details class="gl-mt-6">
        <template v-if="isEligibleToUsePromoCode" #promo-code>
          <promo-code-input />
        </template>
      </summary-details>
    </div>
    <div class="gl-display-none gl-lg-display-block" data-qa-selector="order_summary">
      <h4 class="gl-my-0 gl-font-lg" data-qa-selector="title">{{ titleWithName }}</h4>
      <summary-details class="gl-mt-6">
        <template v-if="isEligibleToUsePromoCode" #promo-code>
          <promo-code-input />
        </template>
      </summary-details>
    </div>
  </gl-card>
</template>
