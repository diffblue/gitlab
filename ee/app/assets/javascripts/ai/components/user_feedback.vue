<script>
import { GlButton } from '@gitlab/ui';
import Tracking from '~/tracking';
import { FEEDBACK_OPTIONS } from '../constants';

export default {
  name: 'UserFeedback',
  components: {
    GlButton,
  },
  mixins: [Tracking.mixin()],
  feedbackOptions: FEEDBACK_OPTIONS,
  props: {
    eventName: {
      type: String,
      required: true,
    },
    promptLocation: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      feedbackValue: '',
    };
  },
  computed: {
    savedFeedbackOption() {
      return this.feedbackValue
        ? FEEDBACK_OPTIONS.find((option) => option.value === this.feedbackValue)
        : null;
    },
  },
  methods: {
    trackFeedback(value) {
      this.feedbackValue = value;
      this.track(this.eventName, {
        action: 'click_button',
        label: 'response_feedback',
        property: value,
        extra: {
          prompt_location: this.promptLocation,
        },
      });
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-mt-6 gl-pb-5">
    <template v-if="!feedbackValue">
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
