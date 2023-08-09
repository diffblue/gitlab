<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { s__ } from '~/locale';
import SharedModal from './shared_modal.vue';

export default {
  components: {
    SharedModal,
  },
  props: {
    statusCheck: {
      type: Object,
      required: true,
    },
  },
  methods: {
    ...mapActions(['putStatusCheck']),
    show() {
      this.$refs.modal.show();
    },
  },
  modalId: 'status-checks-update-modal',
  i18n: {
    title: s__('StatusCheck|Update status check'),
  },
};
</script>

<template>
  <shared-modal
    ref="modal"
    :modal-id="$options.modalId"
    :title="$options.i18n.title"
    :status-check="statusCheck"
    :action="putStatusCheck"
  />
</template>
