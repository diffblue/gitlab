<script>
import { mapState } from 'vuex';
import { __ } from '~/locale';
import GlModalVuex from '~/vue_shared/components/gl_modal_vuex.vue';
import RuleForm from './rule_form.vue';

export default {
  components: {
    GlModalVuex,
    RuleForm,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    isMrEdit: {
      type: Boolean,
      default: true,
      required: false,
    },
  },
  computed: {
    ...mapState('createModal', {
      rule: 'data',
    }),
    title() {
      return !this.rule || this.defaultRuleName
        ? __('Add approval rule')
        : __('Update approval rule');
    },
    defaultRuleName() {
      return this.rule?.defaultRuleName;
    },
    primaryActionProps() {
      return {
        text: this.title,
        attributes: { variant: 'confirm' },
      };
    },
  },
  methods: {
    submit() {
      this.$refs.form.submit();
    },
  },
  cancelActionProps: {
    text: __('Cancel'),
  },
};
</script>

<template>
  <gl-modal-vuex
    modal-module="createModal"
    :modal-id="modalId"
    :title="title"
    :action-primary="primaryActionProps"
    :action-cancel="$options.cancelActionProps"
    size="sm"
    @ok.prevent="submit"
  >
    <rule-form
      ref="form"
      :init-rule="rule"
      :is-mr-edit="isMrEdit"
      :default-rule-name="defaultRuleName"
    />
  </gl-modal-vuex>
</template>
