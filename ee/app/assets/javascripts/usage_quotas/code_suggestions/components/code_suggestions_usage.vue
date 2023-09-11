<script>
import * as Sentry from '@sentry/browser';
import getAddOnPurchaseQuery from 'ee/usage_quotas/add_on/graphql/get_add_on_purchase.query.graphql';
import { ADD_ON_CODE_SUGGESTIONS } from 'ee/usage_quotas/code_suggestions/constants';
import CodeSuggestionsIntro from 'ee/usage_quotas/code_suggestions/components/code_suggestions_intro.vue';

export default {
  name: 'CodeSuggestionsUsage',
  components: { CodeSuggestionsIntro },
  inject: ['fullPath'],
  data() {
    return {
      totalValue: null,
    };
  },
  computed: {
    hasCodeSuggestions() {
      return this.totalValue !== null && this.totalValue > 0;
    },
  },
  apollo: {
    totalValue: {
      query: getAddOnPurchaseQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          addOnName: ADD_ON_CODE_SUGGESTIONS,
        };
      },
      update({ namespace }) {
        return namespace?.addOnPurchase?.purchasedQuantity ?? null;
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
  <code-suggestions-intro v-if="!hasCodeSuggestions" />
</template>
