<script>
import { GlModal, GlFormCheckboxGroup, GlFormGroup, GlFormTextarea } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export const feedbackOptions = [
  {
    text: __('Helpful'),
    value: 'helpful',
  },
  {
    text: __('Unhelpful or irrelevant'),
    value: 'unhelpful',
  },
  {
    text: __('Factually incorrect'),
    value: 'incorrect',
  },
  {
    text: __('Too long'),
    value: 'long',
  },
  {
    text: __('Abusive or offensive'),
    value: 'abuse',
  },
  {
    text: __('Something else'),
    value: 'other',
  },
];

const i18n = {
  MODAL_TITLE: s__('AI|Give feedback on AI content'),
  MODAL_DESCRIPTION: s__(
    'AI|To help improve the quality of the content, send your feedback to GitLab team members.',
  ),
  MODAL_OPTIONS_LABEL: s__('AI|How was the AI content?'),
  MODAL_MORE_LABEL: __('More information'),
  MODAL_MORE_PLACEHOLDER: s__('AI|How could the content be improved?'),
};

export default {
  name: 'DuoChatFeedbackModal',
  components: {
    GlModal,
    GlFormCheckboxGroup,
    GlFormGroup,
    GlFormTextarea,
  },
  data() {
    return {
      selectedFeedbackOptions: [],
      extendedFeedback: '',
    };
  },
  methods: {
    show() {
      this.$refs.feedbackModal.show();
    },
    onFeedbackSubmit() {
      if (this.selectedFeedbackOptions.length) {
        this.$emit('feedback-submitted', {
          feedbackOptions: this.selectedFeedbackOptions,
          extendedFeedback: this.extendedFeedback,
        });
      }
    },
    onFeedbackCanceled() {
      this.$refs.feedbackModal.hide();
    },
  },
  actions: {
    primary: {
      text: __('Submit'),
    },
    cancel: {
      text: __('Cancel'),
    },
  },
  feedbackOptions,
  i18n,
};
</script>
<template>
  <gl-modal
    ref="feedbackModal"
    modal-id="feedbackModal"
    :title="$options.i18n.MODAL_TITLE"
    :action-primary="$options.actions.primary"
    :action-cancel="$options.actions.cancel"
    :visible="false"
    size="sm"
    @primary="onFeedbackSubmit"
    @canceled="onFeedbackCanceled"
  >
    <p>{{ $options.i18n.MODAL_DESCRIPTION }}</p>
    <gl-form-group
      :label="$options.i18n.MODAL_OPTIONS_LABEL"
      :optional="false"
      data-testid="feedback-options"
    >
      <gl-form-checkbox-group
        v-model="selectedFeedbackOptions"
        :options="$options.feedbackOptions"
      />
    </gl-form-group>
    <gl-form-group :label="$options.i18n.MODAL_MORE_LABEL" optional>
      <gl-form-textarea
        v-model="extendedFeedback"
        :placeholder="$options.i18n.MODAL_MORE_PLACEHOLDER"
      />
    </gl-form-group>
  </gl-modal>
</template>
