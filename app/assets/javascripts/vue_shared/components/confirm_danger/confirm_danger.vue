<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import ConfirmDangerModal from './confirm_danger_modal.vue';

export default {
  name: 'ConfirmDanger',
  components: {
    GlButton,
    ConfirmDangerModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    phrase: {
      type: String,
      required: true,
    },
    buttonText: {
      type: String,
      required: true,
    },
  },
  modalId: 'confirm-danger-modal',
};
</script>
<template>
  <div>
    <gl-button
      v-gl-modal="$options.modalId"
      class="gl-button btn btn-danger qa-transfer-button"
      variant="danger"
      :disabled="disabled"
      >{{ buttonText }}</gl-button
    >
    <confirm-danger-modal
      :modal-id="$options.modalId"
      :phrase="phrase"
      @confirm="$emit('confirm')"
    />
  </div>
</template>
