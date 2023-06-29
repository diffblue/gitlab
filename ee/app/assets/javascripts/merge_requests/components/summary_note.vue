<script>
import { GlLink } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserFeedback from 'ee/ai/components/user_feedback.vue';
import SummaryNoteWrapper from './summary_note_wrapper.vue';

export default {
  components: {
    GlLink,
    TimeAgoTooltip,
    UserFeedback,
    SummaryNoteWrapper,
  },
  props: {
    summary: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <summary-note-wrapper>
    <template #title>
      <h5 class="gl-m-0">{{ __('Merge request change summary') }}</h5>
    </template>
    <template #created>
      <time-ago-tooltip
        class="gl-white-space-nowrap gl-font-sm gl-text-gray-600"
        :time="summary.createdAt"
      />
    </template>
    <template #content>
      <p class="gl-m-0">
        {{ summary.content }}
      </p>
    </template>
    <template #feedback>
      <user-feedback
        event-name="proposed_changes_summary"
        size="small"
        icon-only
        category="tertiary"
      />
    </template>
    <template #feedback-link>
      <gl-link href="https://gitlab.com/gitlab-org/gitlab/-/issues/408726" target="_blank">
        {{ __('Leave feedback') }}
      </gl-link>
    </template>
  </summary-note-wrapper>
</template>
