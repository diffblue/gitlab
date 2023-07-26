<script>
import { GlButton, GlIcon, GlLink, GlSkeletonLoader, GlSprintf } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import getAddOnPurchaseQuery from 'ee/usage_quotas/graphql/queries/get_add_on_purchase_query.graphql';
import UsageStatistics from 'ee/usage_quotas/components/usage_statistics.vue';
import {
  ADD_ON_CODE_SUGGESTIONS,
  codeSuggestionsAssignedDescriptionText,
  codeSuggestionsInfoLink,
  codeSuggestionsInfoText,
  codeSuggestionsIntroDescriptionText,
  codeSuggestionsLearnMoreLink,
  learnMoreText,
} from 'ee/usage_quotas/seats/constants';

const COMPONENT_NAME = 'CodeSuggestionsUsageStatisticsCard';

export default {
  name: COMPONENT_NAME,
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
    descriptionText() {
      return this.shouldShowUsageStatistics
        ? this.$options.i18n.codeSuggestionsAssignedDescriptionText
        : this.$options.i18n.codeSuggestionsIntroDescriptionText;
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
        scope.setTag('vue_component', COMPONENT_NAME);
        Sentry.captureException(error);
      });
    },
  },
  helpLinks: {
    codeSuggestionsInfoLink,
    codeSuggestionsLearnMoreLink,
  },
  i18n: {
    codeSuggestionsAssignedDescriptionText,
    codeSuggestionsInfoText,
    codeSuggestionsIntroDescriptionText,
    learnMoreText,
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
        <p class="gl-font-weight-bold gl-mb-0" data-testid="code-suggestions-description">
          <gl-icon name="tanuki-ai" class="gl-text-purple-600 gl-mr-3" />{{ descriptionText }}
        </p>
      </template>
      <template #additional-info>
        <p class="gl-mt-5" data-testid="code-suggestions-info">
          <gl-sprintf :message="$options.i18n.codeSuggestionsInfoText">
            <template #link="{ content }">
              <gl-link
                :href="$options.helpLinks.codeSuggestionsInfoLink"
                target="_blank"
                data-testid="code-suggestions-info-link"
                >{{ content }}</gl-link
              >
            </template>
          </gl-sprintf>
        </p>
      </template>
    </usage-statistics>
    <div v-else class="gl-display-flex gl-sm-flex-direction-column">
      <section>
        <p
          v-if="descriptionText"
          class="gl-font-weight-bold gl-mb-3"
          data-testid="code-suggestions-description"
        >
          <gl-icon name="tanuki-ai" class="gl-text-purple-600 gl-mr-3" />{{ descriptionText }}
        </p>
        <p data-testid="code-suggestions-info">
          <gl-sprintf :message="$options.i18n.codeSuggestionsInfoText">
            <template #link="{ content }">
              <gl-link
                :href="$options.helpLinks.codeSuggestionsInfoLink"
                target="_blank"
                data-testid="code-suggestions-info-link"
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
