<script>
import { GlModal } from '@gitlab/ui';
import { __, s__ } from '~/locale';

import CreateForm from './create_form.vue';
import EditForm from './edit_form.vue';

export default {
  components: {
    GlModal,
    CreateForm,
    EditForm,
  },
  props: {
    framework: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    isEdit() {
      return Boolean(this.framework?.id);
    },
    title() {
      return this.isEdit ? this.$options.i18n.editTitle : this.$options.i18n.addTitle;
    },
  },
  methods: {
    show() {
      this.$refs.modal.show();
    },
    hide() {
      this.$refs.modal.hide();
    },
    onSuccess({ message: successMessage }) {
      this.$emit('change', successMessage);
    },
  },
  i18n: {
    addTitle: s__('ComplianceFrameworks|New compliance framework'),
    editTitle: s__('ComplianceFrameworks|Edit compliance framework'),
    addFramework: s__('ComplianceFrameworks|Add framework'),
    cancel: __('Cancel'),
  },
};
</script>
<template>
  <gl-modal ref="modal" :title="title" modal-id="framework-form-modal" hide-footer>
    <edit-form
      v-if="isEdit"
      :id="framework.id"
      ref="formComponent"
      @cancel="hide"
      @success="onSuccess"
    />
    <create-form v-else ref="formComponent" @cancel="hide" @success="onSuccess" />
  </gl-modal>
</template>
