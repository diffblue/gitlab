<script>
import { GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { s__ } from '~/locale';
import SharedModal from './shared_modal.vue';

export default {
  components: {
    GlButton,
    SharedModal,
  },
  methods: {
    ...mapActions(['postStatusCheck']),
    show() {
      this.$refs.modal.show();
    },
  },
  modalId: 'status-checks-create-modal',
  i18n: {
    addButton: s__('StatusCheck|Add status check'),
    title: s__('StatusCheck|Add status check'),
  },
};
</script>

<template>
  <div>
    <gl-button category="secondary" size="small" @click="show">
      {{ $options.i18n.addButton }}
    </gl-button>
    <shared-modal
      ref="modal"
      :modal-id="$options.modalId"
      :title="$options.i18n.title"
      :action="postStatusCheck"
    />
  </div>
</template>
