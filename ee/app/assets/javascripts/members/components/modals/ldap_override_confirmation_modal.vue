<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { __, s__ } from '~/locale';
import { LDAP_OVERRIDE_CONFIRMATION_MODAL_ID } from '../../constants';

export default {
  name: 'LdapOverrideConfirmationModal',
  i18n: {
    editPermissions: s__('Members|Edit permissions'),
    modalBody: s__(
      'Members|%{userName} is currently an LDAP user. Editing their permissions will override the settings from the LDAP group sync.',
    ),
    toastMessage: s__('Members|LDAP override enabled.'),
  },
  actionCancel: {
    text: __('Cancel'),
  },
  modalId: LDAP_OVERRIDE_CONFIRMATION_MODAL_ID,
  components: { GlModal, GlSprintf },
  inject: ['namespace'],
  data() {
    return {
      busy: false,
    };
  },
  computed: {
    ...mapState({
      memberToOverride(state) {
        return state[this.namespace].memberToOverride;
      },
      ldapOverrideConfirmationModalVisible(state) {
        return state[this.namespace].ldapOverrideConfirmationModalVisible;
      },
    }),
    actionPrimary() {
      return {
        text: this.$options.i18n.editPermissions,
        attributes: {
          variant: 'danger',
          loading: this.busy,
        },
      };
    },
  },
  methods: {
    ...mapActions({
      updateLdapOverride(dispatch, payload) {
        return dispatch(`${this.namespace}/updateLdapOverride`, payload);
      },
      hideLdapOverrideConfirmationModal(dispatch) {
        return dispatch(`${this.namespace}/hideLdapOverrideConfirmationModal`);
      },
    }),
    handlePrimary() {
      this.busy = true;

      this.updateLdapOverride({ memberId: this.memberToOverride.id, override: true })
        .then(() => {
          this.busy = false;
          this.hideLdapOverrideConfirmationModal();
          this.$toast.show(this.$options.i18n.toastMessage);
        })
        .catch(() => {
          this.hideLdapOverrideConfirmationModal();
          this.busy = false;
        });
    },
  },
};
</script>

<template>
  <gl-modal
    v-bind="$attrs"
    :modal-id="$options.modalId"
    :title="$options.i18n.editPermissions"
    :visible="ldapOverrideConfirmationModalVisible"
    :action-primary="actionPrimary"
    :action-cancel="$options.actionCancel"
    size="sm"
    @primary="handlePrimary"
    @hide="hideLdapOverrideConfirmationModal"
  >
    <p v-if="memberToOverride">
      <gl-sprintf :message="$options.i18n.modalBody">
        <template #userName>{{ memberToOverride.user.name }}</template>
      </gl-sprintf>
    </p>
  </gl-modal>
</template>
