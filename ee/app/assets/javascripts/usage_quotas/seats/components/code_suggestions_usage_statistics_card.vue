<script>
import { GlButton, GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import UsageStatistics from 'ee/usage_quotas/components/usage_statistics.vue';
import {
  codeSuggestionsInfoLink,
  codeSuggestionsInfoText,
  codeSuggestionIntroDescriptionText,
  codeSuggestionsLearnMoreLink,
  learnMoreText,
} from 'ee/usage_quotas/seats/constants';

export default {
  name: 'CodeSuggestionsUsageStatisticsCard',
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
    UsageStatistics,
  },
  data() {
    return {
      totalValue: null,
      usageValue: null,
    };
  },
  computed: {
    descriptionText() {
      return this.$options.i18n.codeSuggestionIntroDescriptionText;
    },
    percentage() {
      return Math.round((this.usageValue / this.totalValue) * 100);
    },
    shouldShowUsageStatistics() {
      return Boolean(this.totalValue) && this.percentage >= 0;
    },
  },
  helpLinks: {
    codeSuggestionsInfoLink,
    codeSuggestionsLearnMoreLink,
  },
  i18n: {
    codeSuggestionsInfoText,
    codeSuggestionIntroDescriptionText,
    learnMoreText,
  },
};
</script>
<template>
  <div class="gl-bg-white gl-border-1 gl-border-purple-300 gl-border-solid gl-p-6 gl-rounded-base">
    <usage-statistics
      v-if="shouldShowUsageStatistics"
      :percentage="percentage"
      :total-value="`${totalValue}`"
      :usage-value="`${usageValue}`"
    />
    <div v-else class="gl-display-flex gl-sm-flex-direction-column">
      <section>
        <p class="gl-font-weight-bold gl-mb-3" data-testid="code-suggestions-description">
          <gl-icon name="tanuki-ai" class="gl-text-purple-600 gl-mr-3" />
          {{ descriptionText }}
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
        >
          {{ $options.i18n.learnMoreText }}
        </gl-button>
      </section>
    </div>
  </div>
</template>
