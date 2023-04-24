<script>
import { GlButton, GlSkeletonLoader } from '@gitlab/ui';
import Tracking from '~/tracking';
import { FEEDBACK_OPTIONS } from '../constants';

export default {
  name: 'UserFeedback',
  components: {
    GlButton,
    GlSkeletonLoader,
  },
  mixins: [Tracking.mixin()],
  feedbackOptions: FEEDBACK_OPTIONS,
  props: {
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      feedbackValue: '',
    };
  },
  computed: {
    showFeedbackOptions() {
      return !this.isLoading && !this.feedbackValue;
    },
    savedFeedbackOption() {
      return this.feedbackValue
        ? FEEDBACK_OPTIONS.find((option) => option.value === this.feedbackValue)
        : null;
    },
  },
  watch: {
    isLoading(newVal) {
      if (newVal) {
        this.feedbackValue = '';
      }
    },
  },
  methods: {
    trackFeedback(value) {
      this.feedbackValue = value;
      this.track('explain_code_blob_viewer', {
        action: 'click_button',
        label: 'response_feedback',
        property: value,
        extra: {
          prompt_location: 'before_content',
        },
      });
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-mt-6">
    <gl-skeleton-loader v-if="isLoading" :lines="1" />
    <template v-if="showFeedbackOptions">
      <gl-button
        v-for="option in $options.feedbackOptions"
        :key="option.value"
        class="gl-mr-2"
        variant="default"
        :icon="option.icon"
        @click="trackFeedback(option.value)"
      >
        {{ option.title }}
      </gl-button>
    </template>
    <gl-button
      v-if="savedFeedbackOption"
      disabled
      variant="default"
      :icon="savedFeedbackOption.icon"
    >
      {{ savedFeedbackOption.title }}
    </gl-button>
  </div>
</template>
