<script>
import { GlModal, GlButton, GlSprintf, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'MergeImmediatelyConfirmationDialog',
  components: {
    GlModal,
    GlButton,
    GlSprintf,
    GlLink,
  },
  props: {
    docsUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    bodyText() {
      return __(
        "Merging immediately isn't recommended as it may negatively impact the existing merge train. Read the %{docsLinkStart}documentation%{docsLinkEnd} for more information.",
      );
    },
  },
  methods: {
    show() {
      this.$refs.modal.show();
    },
    cancel() {
      this.hide();
    },
    mergeImmediately() {
      this.$emit('mergeImmediately');
      this.hide();
    },
    hide() {
      this.$refs.modal.hide();
    },
    focusCancelButton() {
      this.$refs.cancelButton.$el.focus();
    },
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    modal-id="merge-immediately-confirmation-dialog"
    :title="__('Merge immediately')"
    @shown="focusCancelButton"
  >
    <p>
      <gl-sprintf :message="bodyText">
        <template #docsLink="{ content }">
          <gl-link :href="docsUrl" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <p>{{ __('Are you sure you want to merge immediately?') }}</p>
    <template #modal-footer>
      <gl-button ref="cancelButton" @click="cancel">{{ __('Cancel') }}</gl-button>
      <gl-button
        variant="danger"
        data-qa-selector="merge_immediately_button"
        @click="mergeImmediately"
        >{{ __('Merge immediately') }}</gl-button
      >
    </template>
  </gl-modal>
</template>
