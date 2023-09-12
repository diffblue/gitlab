<script>
import { GlButton } from '@gitlab/ui';
import DuoChatFeedbackModal from 'ee/ai/components/duo_chat_feedback_modal.vue';
import Tracking from '~/tracking';
import { i18n } from '../constants';

export default {
  name: 'UserFeedback',
  components: {
    GlButton,
    FeedbackModal: DuoChatFeedbackModal,
  },
  mixins: [Tracking.mixin()],
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
    eventExtraData: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    feedbackLinkText: {
      type: String,
      required: false,
      default: i18n.GENIE_CHAT_FEEDBACK_LINK,
    },
  },
  data() {
    return {
      feedbackReceived: false,
    };
  },
  computed: {
    isMRSummaryNote() {
      return this.feedbackLinkText !== i18n.GENIE_CHAT_FEEDBACK_LINK;
    },
  },
  methods: {
    trackFeedback({ feedbackOptions, extendedFeedback } = {}) {
      this.track(this.eventName, {
        action: 'click_button',
        label: 'response_feedback',
        property: feedbackOptions,
        extra: {
          extendedFeedback,
          prompt_location: this.promptLocation,
          ...this.eventExtraData,
        },
      });

      this.feedbackReceived = true;
    },
    requestFeedbackModal() {
      this.$refs.feedbackModal.show();
    },
  },
  i18n,
};
</script>

<template>
  <div>
    <div :class="{ 'gl-pt-4': !isMRSummaryNote }">
      <gl-button v-if="!feedbackReceived" variant="link" @click="$refs.feedbackModal.show()">{{
        feedbackLinkText
      }}</gl-button>
      <span v-else class="gl-text-gray-500">
        {{ $options.i18n.GENIE_CHAT_FEEDBACK_THANKS }}
      </span>
    </div>
    <feedback-modal
      v-if="!feedbackReceived"
      ref="feedbackModal"
      @feedback-submitted="trackFeedback"
    />
  </div>
</template>
