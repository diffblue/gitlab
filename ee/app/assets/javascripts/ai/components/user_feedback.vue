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
    size: {
      type: String,
      required: false,
      default: 'medium',
    },
    category: {
      type: String,
      required: false,
      default: 'primary',
    },
    iconOnly: {
      type: Boolean,
      required: false,
      defualt: false,
    },
    eventExtraData: {
      type: Object,
      required: false,
      default: () => ({}),
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
    feedbackOptions() {
      if (!this.feedbackValue) return FEEDBACK_OPTIONS;

      return FEEDBACK_OPTIONS.filter(({ value }) => value === this.feedbackValue);
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
          ...this.eventExtraData,
        },
      });
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex gl-flex-wrap gl-mb-n2"
    :class="{ 'gl-mt-6 gl-pb-5': size === 'medium' }"
  >
    <gl-button
      v-for="option in feedbackOptions"
      :key="`${option.value}-${feedbackValue}`"
      class="gl-mr-2 gl-mb-2"
      :class="{ 'btn-icon': feedbackValue === '' && iconOnly }"
      variant="default"
      :category="category"
      button-text-classes="gl-xs-display-none"
      :size="size"
      :icon="option.icon"
      :aria-label="option.title"
      :disabled="option.value === feedbackValue"
      @click="trackFeedback(option.value)"
    >
      <template v-if="feedbackValue !== '' || !iconOnly">{{ option.title }}</template>
    </gl-button>
  </div>
</template>
