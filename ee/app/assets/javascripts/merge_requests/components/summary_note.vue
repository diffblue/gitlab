<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserFeedback from 'ee/ai/components/user_feedback.vue';
import SummaryNoteWrapper from './summary_note_wrapper.vue';

export default {
  name: 'SummaryNote',
  components: {
    GlLink,
    GlSprintf,
    TimeAgoTooltip,
    UserFeedback,
    SummaryNoteWrapper,
  },
  props: {
    summary: {
      type: Object,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
  computed: {
    isReviewSummary() {
      return this.type === 'review_summary';
    },
  },
};
</script>

<template>
  <div>
    <summary-note-wrapper :class="{ 'gl-bg-gray-50 gl-ml-5 gl-border-0': isReviewSummary }">
      <template #title>
        <h5 class="gl-m-0">
          <gl-sprintf v-if="isReviewSummary" :message="__('%{linkStart}%{linkEnd} review summary')">
            <template #link>
              <gl-link :href="summary.reviewer.webUrl">@{{ summary.reviewer.username }}</gl-link>
            </template>
            <template #name>
              {{ summary.reviewer.name }}
            </template>
          </gl-sprintf>
          <template v-else>{{ __('Merge request change summary') }}</template>
        </h5>
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
    <summary-note
      v-for="(review, index) in summary.reviewLlmSummaries"
      :key="index"
      :summary="review"
      type="review_summary"
    />
  </div>
</template>
