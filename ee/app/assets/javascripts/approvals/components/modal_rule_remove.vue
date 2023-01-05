<script>
import { GlSprintf } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { n__, __ } from '~/locale';
import GlModalVuex from '~/vue_shared/components/gl_modal_vuex.vue';

const i18n = {
  cancelButtonText: __('Cancel'),
  primaryButtonText: __('Remove approvers'),
  modalTitle: __('Remove approvers?'),
  removeWarningText: (i) =>
    n__(
      'ApprovalRuleRemove|You are about to remove the %{name} approver group which has %{strongStart}%{count} member%{strongEnd}. Approvals from this member are not revoked.',
      'ApprovalRuleRemove|You are about to remove the %{name} approver group which has %{strongStart}%{count} members%{strongEnd}. Approvals from these members are not revoked.',
      i,
    ),
};

export default {
  components: {
    GlModalVuex,
    GlSprintf,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState('deleteModal', {
      rule: 'data',
    }),
    approversCount() {
      return this.rule.eligibleApprovers.length;
    },
    membersText() {
      return n__(
        'ApprovalRuleRemove|%d member',
        'ApprovalRuleRemove|%d members',
        this.rule.approvers.length,
      );
    },
    modalText() {
      return i18n.removeWarningText(this.approversCount);
    },
    primaryButtonProps() {
      return {
        text: i18n.primaryButtonText,
        attributes: { variant: 'danger' },
      };
    },
  },
  methods: {
    ...mapActions(['deleteRule']),
    submit() {
      this.deleteRule(this.rule.id);
    },
  },
  cancelButtonProps: {
    text: i18n.cancelButtonText,
  },
  i18n,
};
</script>

<template>
  <gl-modal-vuex
    modal-module="deleteModal"
    :modal-id="modalId"
    :title="$options.i18n.modalTitle"
    :action-primary="primaryButtonProps"
    :action-cancel="$options.cancelButtonProps"
    @ok.prevent="submit"
  >
    <p v-if="rule">
      <gl-sprintf :message="modalText">
        <template #name>
          <strong>{{ rule.name }}</strong>
        </template>
        <template #strong="{ content }">
          <strong>
            <gl-sprintf :message="content">
              <template #count>{{ approversCount }}</template>
            </gl-sprintf>
          </strong>
        </template>
      </gl-sprintf>
    </p>
  </gl-modal-vuex>
</template>
