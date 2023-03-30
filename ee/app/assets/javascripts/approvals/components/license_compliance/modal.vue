<script>
import { GlButton, GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { mapState } from 'vuex';
import { APPROVALS_MODAL } from 'ee/approvals/stores/modules/license_compliance';
import { __ } from '~/locale';
import GlModalVuex from '~/vue_shared/components/gl_modal_vuex.vue';
import RuleForm from '../rule_form.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
    GlModalVuex,
    RuleForm,
  },
  computed: {
    ...mapState({
      documentationPath: ({ settings }) => settings.approvalsDocumentationPath,
      licenseApprovalRule(state) {
        return state[APPROVALS_MODAL].data;
      },
    }),
    title() {
      return this.licenseApprovalRule ? __('Update approvers') : __('Add approvers');
    },
  },
  methods: {
    submit() {
      this.$refs.form.submit();
    },
  },
  modalModule: APPROVALS_MODAL,
};
</script>

<template>
  <gl-modal-vuex
    :modal-module="$options.modalModule"
    modal-id="licenseComplianceApproval"
    :title="title"
    size="sm"
    @ok="submit"
  >
    <rule-form ref="form" :init-rule="licenseApprovalRule" />
    <template #modal-footer="{ ok, cancel }">
      <section class="gl-display-flex gl-w-full">
        <p>
          <gl-icon name="question-o" :size="12" class="gl-text-blue-600" />
          <gl-sprintf
            :message="
              s__('LicenseCompliance|Learn more about %{linkStart}License Approvals%{linkEnd}')
            "
          >
            <template #link="{ content }">
              <gl-link :href="documentationPath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
        <div class="gl-ml-auto">
          <gl-button name="cancel" @click="cancel">{{ __('Cancel') }}</gl-button>
          <gl-button name="ok" category="primary" variant="confirm" @click="ok">{{
            title
          }}</gl-button>
        </div>
      </section>
    </template>
  </gl-modal-vuex>
</template>
