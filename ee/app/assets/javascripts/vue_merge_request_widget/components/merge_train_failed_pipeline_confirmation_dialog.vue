<script>
import { GlModal, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'MergeTrainFailedPipelineConfirmationDialog',
  i18n: {
    title: __('Start merge train'),
    cancel: __('Cancel'),
    info: __('The latest pipeline for this merge request has failed.'),
    confirmation: __('Are you sure you want to attempt to merge?'),
  },
  components: {
    GlModal,
    GlButton,
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    hide() {
      this.$refs.modal.hide();
    },
    cancel() {
      this.hide();
      this.$emit('cancel');
    },
    focusCancelButton() {
      this.$refs.cancelButton.$el.focus();
    },
    startMergeTrain() {
      this.$emit('startMergeTrain');
      this.hide();
    },
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    modal-id="merge-train-failed-pipeline-confirmation-dialog"
    size="sm"
    :title="$options.i18n.title"
    :visible="visible"
    @shown="focusCancelButton"
    @hide="$emit('cancel')"
  >
    <p>{{ $options.i18n.info }}</p>
    <p>{{ $options.i18n.confirmation }}</p>
    <template #modal-footer>
      <gl-button ref="cancelButton" @click="cancel">{{ $options.i18n.cancel }}</gl-button>
      <gl-button variant="danger" data-testid="start-merge-train" @click="startMergeTrain">
        {{ $options.i18n.title }}
      </gl-button>
    </template>
  </gl-modal>
</template>
