<script>
import { GlModal } from '@gitlab/ui';
import { s__ } from '~/locale';

import CreateForm from './create_form.vue';

export default {
  components: {
    GlModal,
    CreateForm,
  },
  methods: {
    show() {
      this.$refs.modal.show();
    },
    hide() {
      this.$refs.modal.hide();
    },
    onSuccess(successMessage) {
      this.$emit('change', successMessage);
    },
  },
  i18n: {
    title: s__('ComplianceFrameworks|New compliance framework'),
  },
};
</script>
<template>
  <gl-modal ref="modal" :title="$options.i18n.title" modal-id="framework-form-modal" hide-footer>
    <create-form @cancel="hide" @success="onSuccess" />
  </gl-modal>
</template>
