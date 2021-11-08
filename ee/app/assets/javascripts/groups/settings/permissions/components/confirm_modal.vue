<script>
import { GlModal } from '@gitlab/ui';

export default {
  components: {
    GlModal,
  },
  props: {
    modalOptions: {
      type: Object,
      required: true,
    },
  },
  methods: {
    submitForm() {
      const groupPermissionsForm = document.querySelector('.js-general-permissions-form');
      groupPermissionsForm.dataset.modalConfirmed = true;
      groupPermissionsForm.submit();
    },
  },
};
</script>
<template>
  <gl-modal visible v-bind="modalOptions" @primary="submitForm">
    {{ modalOptions.text }}
  </gl-modal>
</template>
