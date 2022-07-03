<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';

export default {
  components: { GlAlert, GlLink, GlSprintf },
  methods: {
    feedbackUrl(template) {
      return `https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/feedback/-/issues/new?issuable_template=${template}`;
    },
  },
};
</script>

<template>
  <gl-alert :dismissible="false" variant="info">
    {{ __('This is an experimental feature developed by GitLab Incubation Engineering.') }}
    <gl-sprintf
      :message="
        __(
          'We invite you to %{featureLinkStart}request a feature%{featureLinkEnd}, %{bugLinkStart}report a bug%{bugLinkEnd} or %{feedbackLinkStart}share feedback%{feedbackLinkEnd}',
        )
      "
    >
      <template #featureLink="{ content }">
        <gl-link :href="feedbackUrl('feature_request')">{{ content }}</gl-link>
      </template>
      <template #bugLink="{ content }">
        <gl-link :href="feedbackUrl('report_bug')">{{ content }}</gl-link>
      </template>
      <template #feedbackLink="{ content }">
        <gl-link :href="feedbackUrl('general_feedback')">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
