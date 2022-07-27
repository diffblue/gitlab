<script>
import { GlBanner } from '@gitlab/ui';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { i18n, FEEDBACK_ISSUE_URL } from '../constants';

export default {
  components: {
    GlBanner,
    UserCalloutDismisser,
  },
  inject: ['projectQualitySummaryFeedbackImagePath'],
  FEEDBACK_ISSUE_URL,
  i18n,
};
</script>
<template>
  <user-callout-dismisser ref="calloutDismisser" feature-name="project_quality_summary_feedback">
    <template #default="{ dismiss, shouldShowCallout }">
      <gl-banner
        v-if="shouldShowCallout"
        class="gl-mt-6"
        :title="$options.i18n.banner.title"
        :button-text="$options.i18n.banner.button"
        :button-link="$options.FEEDBACK_ISSUE_URL"
        :svg-path="projectQualitySummaryFeedbackImagePath"
        @close="dismiss"
      >
        <p>{{ $options.i18n.banner.text }}</p>
      </gl-banner>
    </template>
  </user-callout-dismisser>
</template>
