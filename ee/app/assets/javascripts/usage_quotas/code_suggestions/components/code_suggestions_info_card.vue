<script>
import { GlCard, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import UsageStatistics from 'ee/usage_quotas/components/usage_statistics.vue';
import { codeSuggestionsLearnMoreLink } from 'ee/usage_quotas/code_suggestions/constants';

export default {
  name: 'CodeSuggestionsUsageInfoCard',
  helpLinks: {
    codeSuggestionsLearnMoreLink,
  },
  i18n: {
    description: s__(
      `CodeSuggestions|%{linkStart}Code Suggestions%{linkEnd} uses generative AI to suggest code while you're developing.`,
    ),
    title: s__('CodeSuggestions|Code Suggestions add-on'),
  },
  components: {
    GlCard,
    GlLink,
    GlSprintf,
    UsageStatistics,
  },
};
</script>
<template>
  <gl-card class="gl-p-3">
    <usage-statistics>
      <template #description>
        <p class="gl-font-weight-bold gl-mb-0" data-testid="title">{{ $options.i18n.title }}</p>
      </template>
      <template #additional-info>
        <p class="gl-mt-5" data-testid="description">
          <gl-sprintf :message="$options.i18n.description">
            <template #link="{ content }">
              <gl-link :href="$options.helpLinks.codeSuggestionsLearnMoreLink" target="_blank">{{
                content
              }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
      </template>
    </usage-statistics>
  </gl-card>
</template>
