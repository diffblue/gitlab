<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';

export default {
  name: 'DismissalCommentModalFooter',
  components: {
    GlButton,
  },
  props: {
    isDismissingVulnerability: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDismissed: {
      type: Boolean,
      required: false,
      default: false,
    },
    isEditingExistingFeedback: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    submitLabel() {
      if (this.isEditingExistingFeedback) {
        return s__('vulnerability|Save comment');
      }
      if (this.isDismissed) {
        return s__('vulnerability|Add comment');
      }
      return s__('vulnerability|Add comment & dismiss');
    },
  },
  methods: {
    addCommentAndDismiss() {
      Tracking.event(document.body.dataset.page, 'click_add_comment_and_dismiss');
      this.$emit('addCommentAndDismiss');
    },
    addDismissalComment() {
      if (this.isEditingExistingFeedback) {
        Tracking.event(document.body.dataset.page, 'click_edit_comment');
      } else {
        Tracking.event(document.body.dataset.page, 'click_add_comment');
      }

      this.$emit('addDismissalComment');
    },
    handleSubmit() {
      if (this.isDismissed) {
        this.addDismissalComment();
      } else {
        this.addCommentAndDismiss();
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-button variant="default" category="primary" class="js-cancel" @click="$emit('cancel')">
      {{ __('Cancel') }}
    </gl-button>
    <gl-button
      :loading="isDismissingVulnerability"
      :disabled="isDismissingVulnerability"
      data-qa-selector="add_and_dismiss_button"
      data-testid="add_and_dismiss_button"
      @click="handleSubmit"
    >
      {{ submitLabel }}
    </gl-button>
  </div>
</template>
