<script>
import { GlIcon } from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
import { sprintf, s__ } from '~/locale';
import { trackCheckout } from '~/google_tag_manager';
import formattingMixins from '../formatting_mixins';
import SummaryDetails from './order_summary/summary_details.vue';

export default {
  components: {
    SummaryDetails,
    GlIcon,
  },
  mixins: [formattingMixins],
  data() {
    return {
      collapsed: true,
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
  methods: {
    toggleCollapse() {
      this.collapsed = !this.collapsed;
    },
  },
  i18n: {
    title: s__("Checkout|%{name}'s GitLab subscription"),
  },
};
</script>
<template>
  <div
    v-if="!isGroupSelected || isSelectedGroupPresent"
    class="order-summary gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-mt-2 mt-lg-5"
  >
    <div class="d-lg-none">
      <div @click="toggleCollapse">
        <h4 class="d-flex justify-content-between gl-font-lg" :class="{ 'gl-mb-7': !collapsed }">
          <div class="d-flex">
            <gl-icon v-if="collapsed" name="chevron-right" />
            <gl-icon v-else name="chevron-down" />
            <div>{{ titleWithName }}</div>
          </div>
          <div class="gl-ml-3">{{ formatAmount(totalAmount, usersPresent) }}</div>
        </h4>
      </div>
      <summary-details v-show="!collapsed" />
    </div>
    <div class="d-none d-lg-block">
      <div class="append-bottom-20">
        <h4>
          {{ titleWithName }}
        </h4>
      </div>
      <summary-details />
    </div>
  </div>
</template>
