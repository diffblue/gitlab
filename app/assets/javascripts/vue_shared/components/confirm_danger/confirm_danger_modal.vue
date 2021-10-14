<script>
import { GlModal, GlFormGroup, GlFormInput, GlSprintf } from '@gitlab/ui';
import {
  CONFIRM_DANGER_MODAL_BUTTON,
  CONFIRM_DANGER_MODAL_TITLE,
  CONFIRM_DANGER_PHRASE_TEXT,
  CONFIRM_DANGER_WARNING,
} from './constants';

export default {
  name: 'ConfirmDangerModal',
  components: {
    GlModal,
    GlFormGroup,
    GlFormInput,
    GlSprintf,
  },
  inject: {
    confirmDangerMessage: {
      default: '',
    },
    confirmButtonText: {
      default: CONFIRM_DANGER_MODAL_BUTTON,
    },
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    phrase: {
      type: String,
      required: true,
    },
  },
  data() {
    return { confirmationPhrase: '' };
  },
  computed: {
    isValid() {
      return this.phrase.length && this.equalString(this.confirmationPhrase, this.phrase);
    },
    actionPrimary() {
      console.log('this.$options.i18n', this.$options.i18n);
      return {
        text: this.$options.i18n.CONFIRM_DANGER_MODAL_BUTTON,
        attributes: [{ variant: 'danger', disabled: this.isValid }],
      };
    },
  },
  methods: {
    equalString(a, b) {
      return a.trim().toLowerCase() === b.trim().toLowerCase();
    },
  },
  i18n: {
    CONFIRM_DANGER_MODAL_BUTTON,
    CONFIRM_DANGER_MODAL_TITLE,
    CONFIRM_DANGER_WARNING,
    CONFIRM_DANGER_PHRASE_TEXT,
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    class="qa-confirm-modal"
    :modal-id="modalId"
    :data-testid="modalId"
    :title="$options.i18n.CONFIRM_DANGER_MODAL_TITLE"
    :action-primary="actionPrimary"
    @primary="$emit('confirm')"
  >
    <p class="text-danger js-confirm-text">{{ confirmDangerMessage }}</p>
    <p>
      <span class="js-warning-text">{{ $options.i18n.CONFIRM_DANGER_MODAL_WARNING }}</span>
      <gl-sprintf :message="$options.i18n.CONFIRM_DANGER_PHRASE_TEXT">
        <template #code>
          <code class="js-confirm-danger-match">{{ phrase }}</code>
        </template>
      </gl-sprintf>
    </p>
    <gl-form-group class="'form-control js-confirm-danger-input qa-confirm-input'" :state="isValid">
      <gl-form-input v-model="confirmationPhrase" type="text" />
    </gl-form-group>
  </gl-modal>
</template>
