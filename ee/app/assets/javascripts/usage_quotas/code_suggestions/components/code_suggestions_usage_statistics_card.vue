<script>
import { GlCard } from '@gitlab/ui';
import { s__ } from '~/locale';
import UsageStatistics from 'ee/usage_quotas/components/usage_statistics.vue';
import { codeSuggestionsLearnMoreLink } from 'ee/usage_quotas/code_suggestions/constants';

export default {
  name: 'CodeSuggestionsUsageStatisticsCard',
  helpLinks: {
    codeSuggestionsLearnMoreLink,
  },
  i18n: {
    codeSuggestionsAssignedInfoText: s__('CodeSuggestions|Code Suggestions seats used'),
    codeSuggestionsIntroDescriptionText: s__(
      `CodeSuggestions|A user can be assigned a Code Suggestion seat only once each billable month.`,
    ),
  },
  components: {
    GlCard,
    UsageStatistics,
  },
  props: {
    usageValue: {
      type: Number,
      required: true,
    },
    totalValue: {
      type: Number,
      required: true,
    },
  },
  computed: {
    percentage() {
      return Math.round((this.usageValue / this.totalValue) * 100);
    },
    shouldShowUsageStatistics() {
      return Boolean(this.totalValue) && this.percentage >= 0;
    },
  },
};
</script>
<template>
  <gl-card v-if="shouldShowUsageStatistics" class="gl-p-3">
    <usage-statistics
      :percentage="percentage"
      :total-value="`${totalValue}`"
      :usage-value="`${usageValue}`"
    >
      <template #description>
        <p class="gl-font-sm gl-font-weight-bold gl-mb-0" data-testid="code-suggestions-info">
          {{ $options.i18n.codeSuggestionsAssignedInfoText }}
        </p>
      </template>
      <template #additional-info>
        <p class="gl-font-sm gl-mt-5" data-testid="code-suggestions-description">
          {{ $options.i18n.codeSuggestionsIntroDescriptionText }}
        </p>
      </template>
    </usage-statistics>
  </gl-card>
</template>
