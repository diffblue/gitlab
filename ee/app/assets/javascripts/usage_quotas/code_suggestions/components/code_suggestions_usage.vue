<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import getAddOnPurchaseQuery from 'ee/usage_quotas/add_on/graphql/get_add_on_purchase.query.graphql';
import { ADD_ON_CODE_SUGGESTIONS } from 'ee/usage_quotas/code_suggestions/constants';
import AddOnEligibleUserList from 'ee/usage_quotas/code_suggestions/components/add_on_eligible_user_list.vue';
import CodeSuggestionsInfoCard from './code_suggestions_info_card.vue';
import CodeSuggestionsIntro from './code_suggestions_intro.vue';
import CodeSuggestionsStatisticsCard from './code_suggestions_usage_statistics_card.vue';

export default {
  name: 'CodeSuggestionsUsage',
  components: {
    AddOnEligibleUserList,
    CodeSuggestionsInfoCard,
    CodeSuggestionsIntro,
    CodeSuggestionsStatisticsCard,
    GlSkeletonLoader,
  },
  inject: ['fullPath'],
  data() {
    return {
      addOnPurchase: undefined,
    };
  },
  computed: {
    totalValue() {
      return this.addOnPurchase?.purchasedQuantity ?? 0;
    },
    usageValue() {
      return this.addOnPurchase?.assignedQuantity ?? 0;
    },
    hasCodeSuggestions() {
      return this.totalValue !== null && this.totalValue > 0;
    },
    isLoading() {
      return this.$apollo.queries.addOnPurchase.loading;
    },
  },
  apollo: {
    addOnPurchase: {
      query: getAddOnPurchaseQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          addOnName: ADD_ON_CODE_SUGGESTIONS,
        };
      },
      update({ namespace }) {
        return namespace?.addOnPurchase;
      },
      error(error) {
        this.reportError(error);
      },
    },
  },
  methods: {
    reportError(error) {
      Sentry.withScope((scope) => {
        scope.setTag('vue_component', this.$options.name);
        Sentry.captureException(error);
      });
    },
  },
};
</script>

<template>
  <section>
    <section
      v-if="isLoading"
      class="gl-display-grid gl-md-grid-template-columns-2 gl-gap-5 gl-mt-5"
    >
      <div class="gl-bg-white gl-border gl-p-5 gl-rounded-base">
        <gl-skeleton-loader :height="64">
          <rect width="140" height="30" x="5" y="0" rx="4" />
          <rect width="240" height="10" x="5" y="40" rx="4" />
          <rect width="340" height="10" x="5" y="54" rx="4" />
        </gl-skeleton-loader>
      </div>

      <div class="gl-bg-white gl-border gl-p-5 gl-rounded-base">
        <gl-skeleton-loader :height="64">
          <rect width="240" height="10" x="5" y="0" rx="4" />
          <rect width="340" height="10" x="5" y="14" rx="4" />
          <rect width="220" height="8" x="5" y="40" rx="4" />
          <rect width="220" height="8" x="5" y="54" rx="4" />
        </gl-skeleton-loader>
      </div>
    </section>
    <template v-else>
      <section v-if="hasCodeSuggestions">
        <section
          class="gl-display-grid gl-md-grid-template-columns-2 gl-gap-5 gl-bg-gray-10 gl-p-5"
        >
          <code-suggestions-statistics-card :total-value="totalValue" :usage-value="usageValue" />
          <code-suggestions-info-card />
        </section>
        <add-on-eligible-user-list :add-on-purchase-id="addOnPurchase.id" />
      </section>
      <code-suggestions-intro v-else />
    </template>
  </section>
</template>
