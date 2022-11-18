<script>
import { GlBadge, GlFormInput, GlModal, GlSprintf } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import {
  REMOVE_BILLABLE_MEMBER_MODAL_ID,
  REMOVE_BILLABLE_MEMBER_MODAL_CONTENT_TEXT_TEMPLATE,
} from 'ee/usage_quotas/seats/constants';
import csrf from '~/lib/utils/csrf';
import { __, s__, sprintf } from '~/locale';

export default {
  name: 'RemoveBillableMemberModal',
  csrf,
  components: {
    GlFormInput,
    GlModal,
    GlSprintf,
    GlBadge,
  },
  data() {
    return {
      enteredMemberUsername: null,
    };
  },
  computed: {
    ...mapState(['namespaceName', 'namespaceId', 'billableMemberToRemove']),
    modalTitle() {
      return sprintf(s__('Billing|Remove user %{username} from your subscription'), {
        username: this.usernameWithAtPrepended,
      });
    },
    canSubmit() {
      return this.enteredMemberUsername === this.billableMemberToRemove.username;
    },
    modalText() {
      return REMOVE_BILLABLE_MEMBER_MODAL_CONTENT_TEXT_TEMPLATE;
    },
    actionPrimaryProps() {
      return {
        text: __('Remove user'),
        attributes: {
          variant: 'danger',
          disabled: !this.canSubmit,
          class: 'gl-xs-w-full',
        },
      };
    },
    actionCancelProps() {
      return {
        text: __('Cancel'),
        attributes: {
          class: 'gl-xs-w-full',
        },
      };
    },
    usernameWithAtPrepended() {
      return `@${this.billableMemberToRemove.username}`;
    },
  },
  methods: {
    ...mapActions(['removeBillableMember', 'setBillableMemberToRemove']),
  },
  modalId: REMOVE_BILLABLE_MEMBER_MODAL_ID,
  i18n: {
    inputLabel: s__('Billing|Type %{username} to confirm'),
  },
};
</script>

<template>
  <gl-modal
    v-if="billableMemberToRemove"
    :modal-id="$options.modalId"
    :action-primary="actionPrimaryProps"
    :action-cancel="actionCancelProps"
    :title="modalTitle"
    data-testid="remove-billable-member-modal"
    :ok-disabled="!canSubmit"
    @primary="removeBillableMember"
    @hide="setBillableMemberToRemove(null)"
  >
    <p>
      <gl-sprintf :message="modalText">
        <template #username>
          <strong>{{ usernameWithAtPrepended }}</strong>
        </template>
        <template #namespace>{{ namespaceName }}</template>
      </gl-sprintf>
    </p>

    <label id="input-label">
      <gl-sprintf :message="$options.i18n.inputLabel">
        <template #username>
          <gl-badge variant="danger">{{ billableMemberToRemove.username }}</gl-badge>
        </template>
      </gl-sprintf>
    </label>
    <gl-form-input v-model.trim="enteredMemberUsername" aria-labelledby="input-label" />
  </gl-modal>
</template>
