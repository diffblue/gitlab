<script>
import { GlButton, GlModal } from '@gitlab/ui';
import createFlash from '~/flash';
import { sprintf, __ } from '~/locale';
import lockPathMutation from '~/repository/mutations/lock_path.mutation.graphql';

export default {
  i18n: {
    lock: __('Lock'),
    unlock: __('Unlock'),
    modalTitle: __('Lock File?'),
    actionPrimary: __('Okay'),
    actionCancel: __('Cancel'),
  },
  components: {
    GlButton,
    GlModal,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    isLocked: {
      type: Boolean,
      required: true,
    },
    canLock: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isModalVisible: false,
      lockLoading: false,
      locked: this.isLocked,
    };
  },
  computed: {
    lockButtonTitle() {
      return this.locked ? this.$options.i18n.unlock : this.$options.i18n.lock;
    },
    lockConfirmText() {
      return sprintf(__('Are you sure you want to %{action} %{name}?'), {
        action: this.lockButtonTitle.toLowerCase(),
        name: this.name,
      });
    },
  },
  methods: {
    hideModal() {
      this.isModalVisible = false;
    },
    handleModalPrimary() {
      this.toggleLock();
    },
    showModal() {
      this.isModalVisible = true;
    },
    toggleLock() {
      this.lockLoading = true;
      this.$apollo
        .mutate({
          mutation: lockPathMutation,
          variables: {
            filePath: this.path,
            projectPath: this.projectPath,
            lock: !this.locked,
          },
        })
        .catch((error) => {
          createFlash({ message: error, captureError: true, error });
        })
        .finally(() => {
          this.locked = !this.locked;
          this.lockLoading = false;
        });
    },
  },
};
</script>

<template>
  <gl-button :disabled="!canLock" :loading="lockLoading" @click="showModal">
    {{ lockButtonTitle }}
    <gl-modal
      modal-id="lock-file-modal"
      :visible="isModalVisible"
      :title="$options.i18n.modalTitle"
      :action-primary="{ text: $options.i18n.actionPrimary }"
      :action-cancel="{ text: $options.i18n.actionCancel }"
      @primary="handleModalPrimary"
      @hide="hideModal"
    >
      <p>
        {{ lockConfirmText }}
      </p>
    </gl-modal>
  </gl-button>
</template>
