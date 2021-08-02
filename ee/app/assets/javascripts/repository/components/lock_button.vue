<script>
import { GlButton } from '@gitlab/ui';
import createFlash from '~/flash';
import { sprintf, __ } from '~/locale';
import lockPathMutation from '~/repository/mutations/lock_path.mutation.graphql';

export default {
  i18n: {
    lock: __('Lock'),
    unlock: __('Unlock'),
  },
  components: {
    GlButton,
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
      lockLoading: false,
    };
  },
  computed: {
    lockButtonTitle() {
      return this.isLocked ? this.$options.i18n.unlock : this.$options.i18n.lock;
    },
    lockConfirmText() {
      return sprintf(__('Are you sure you want to %{action} %{name}?'), {
        action: this.lockButtonTitle.toLowerCase(),
        name: this.name,
      });
    },
  },
  methods: {
    onLockToggle() {
      // eslint-disable-next-line no-alert
      if (window.confirm(this.lockConfirmText)) {
        this.toggleLock();
      }
    },
    toggleLock() {
      this.lockLoading = true;
      this.$apollo
        .mutate({
          mutation: lockPathMutation,
          variables: {
            filePath: this.path,
            projectPath: this.projectPath,
            lock: !this.isLocked,
          },
        })
        .catch((error) => {
          createFlash({ message: error, captureError: true, error });
        })
        .finally(() => {
          this.lockLoading = false;
        });
    },
  },
};
</script>

<template>
  <gl-button v-if="canLock" :loading="lockLoading" @click="onLockToggle">
    {{ lockButtonTitle }}
  </gl-button>
</template>
