<script>
import { GlButton, GlIcon, GlLink, GlSkeletonLoader, GlSprintf } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { s__ } from '~/locale';
import getAddOnPurchaseQuery from 'ee/usage_quotas/add_on/graphql/get_add_on_purchase.query.graphql';
import UsageStatistics from 'ee/usage_quotas/components/usage_statistics.vue';
import {
  ADD_ON_CODE_SUGGESTIONS,
  codeSuggestionsDescriptionLink,
  codeSuggestionsLearnMoreLink,
} from 'ee/usage_quotas/code_suggestions/constants';
import { learnMoreText } from 'ee/usage_quotas/seats/constants';

export default {
  name: 'CodeSuggestionsUsageStatisticsCard',
  helpLinks: {
    codeSuggestionsDescriptionLink,
    codeSuggestionsLearnMoreLink,
  },
  i18n: {
    codeSuggestionsAssignedInfoText: s__('CodeSuggestions|Code Suggestions add-on assigned'),
    codeSuggestionsInfoText: s__('CodeSuggestions|Introducing the Code Suggestions add-on'),
    codeSuggestionsIntroDescriptionText: s__(
      `CodeSuggestions|Enhance your coding experience with intelligent recommendations. %{linkStart}Code Suggestions%{linkEnd} uses generative AI to suggest code while you're developing.`,
    ),
    learnMoreText,
  },
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
    GlSkeletonLoader,
    UsageStatistics,
  },
  inject: ['fullPath'],
  data() {
    return {
      addOnPurchase: {
        totalValue: null,
        usageValue: null,
      },
    };
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
        return {
          totalValue: namespace?.addOnPurchase?.purchasedQuantity ?? null,
          usageValue: namespace?.addOnPurchase?.assignedQuantity ?? null,
        };
      },
      error(error) {
        this.reportError(error);
      },
    },
  },
  computed: {
    infoText() {
      return this.shouldShowUsageStatistics
        ? this.$options.i18n.codeSuggestionsAssignedInfoText
        : this.$options.i18n.codeSuggestionsInfoText;
    },
    isLoading() {
      return this.$apollo.loading;
    },
    percentage() {
      return Math.round((this.addOnPurchase.usageValue / this.addOnPurchase.totalValue) * 100);
    },
    shouldShowUsageStatistics() {
      return Boolean(this.addOnPurchase.totalValue) && this.percentage >= 0;
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
  <div class="gl-bg-white gl-border-1 gl-border-purple-300 gl-border-solid gl-p-6 gl-rounded-base">
    <gl-skeleton-loader v-if="isLoading" :height="64">
      <rect width="140" height="30" x="0" y="0" rx="4" />
      <rect width="240" height="10" x="0" y="40" rx="4" />
      <rect width="340" height="10" x="0" y="54" rx="4" />
    </gl-skeleton-loader>
    <usage-statistics
      v-else-if="shouldShowUsageStatistics"
      :percentage="percentage"
      :total-value="`${addOnPurchase.totalValue}`"
      :usage-value="`${addOnPurchase.usageValue}`"
    >
      <template #description>
        <p class="gl-font-weight-bold gl-mb-0" data-testid="code-suggestions-info">
          <gl-icon name="tanuki-ai" class="gl-text-purple-600 gl-mr-3" />{{ infoText }}
        </p>
      </template>
      <template #additional-info>
        <p class="gl-mt-5" data-testid="code-suggestions-description">
          <gl-sprintf :message="$options.i18n.codeSuggestionsIntroDescriptionText">
            <template #link="{ content }">
              <gl-link
                :href="$options.helpLinks.codeSuggestionsDescriptionLink"
                target="_blank"
                data-testid="code-suggestions-description-link"
                >{{ content }}</gl-link
              >
            </template>
          </gl-sprintf>
        </p>
      </template>
    </usage-statistics>
    <div v-else class="gl-display-flex gl-sm-flex-direction-column">
      <section>
        <p v-if="infoText" class="gl-font-weight-bold gl-mb-3" data-testid="code-suggestions-info">
          <gl-icon name="tanuki-ai" class="gl-text-purple-600 gl-mr-3" />{{ infoText }}
        </p>
        <p data-testid="code-suggestions-description">
          <gl-sprintf :message="$options.i18n.codeSuggestionsIntroDescriptionText">
            <template #link="{ content }">
              <gl-link
                :href="$options.helpLinks.codeSuggestionsDescriptionLink"
                target="_blank"
                data-testid="code-suggestions-description-link"
                >{{ content }}</gl-link
              >
            </template>
          </gl-sprintf>
        </p>
      </section>
      <section>
        <gl-button
          :href="$options.helpLinks.codeSuggestionsLearnMoreLink"
          category="primary"
          target="_blank"
          size="small"
          variant="default"
          data-testid="learn-more"
          data-qa-selector="learn_more"
          >{{ $options.i18n.learnMoreText }}</gl-button
        >
      </section>
    </div>
  </div>
</template>
