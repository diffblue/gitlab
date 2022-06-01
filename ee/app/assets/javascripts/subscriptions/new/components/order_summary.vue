<script>
import { GlCard, GlIcon, GlCollapse, GlCollapseToggleDirective } from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
import { sprintf, s__ } from '~/locale';
import { trackCheckout } from '~/google_tag_manager';
import formattingMixins from '../formatting_mixins';
import SummaryDetails from './order_summary/summary_details.vue';

export default {
  components: {
    SummaryDetails,
    GlCard,
    GlIcon,
    GlCollapse,
  },
  directives: {
    GlCollapseToggle: GlCollapseToggleDirective,
  },
  mixins: [formattingMixins],
  data() {
    return {
      summaryDetailsAreVisible: false,
    };
  },
  computed: {
    ...mapState(['numberOfUsers', 'selectedPlan']),
    ...mapGetters([
      'selectedPlanText',
      'totalAmount',
      'name',
      'usersPresent',
      'isGroupSelected',
      'isSelectedGroupPresent',
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
        v-gl-collapse-toggle.summary-details
        class="gl-display-flex gl-justify-content-space-between gl-font-lg gl-mt-0 gl-mb-0"
        :class="{ 'gl-mb-6': summaryDetailsAreVisible }"
      >
        <div class="gl-display-flex gl-align-items-center">
          <gl-icon v-if="summaryDetailsAreVisible" name="chevron-down" />
          <gl-icon v-else name="chevron-right" />
          <span>{{ titleWithName }}</span>
        </div>
        <span class="gl-ml-3">{{ formatAmount(totalAmount, usersPresent) }}</span>
      </h4>
      <gl-collapse id="summary-details" v-model="summaryDetailsAreVisible">
        <summary-details />
      </gl-collapse>
    </div>
    <div class="gl-display-none gl-lg-display-block">
      <h4 class="gl-mt-0 gl-mb-6">{{ titleWithName }}</h4>
      <summary-details />
    </div>
  </gl-card>
</template>
