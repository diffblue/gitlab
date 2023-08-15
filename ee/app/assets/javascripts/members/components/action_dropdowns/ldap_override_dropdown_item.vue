<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';

export default {
  name: 'LdapOverrideDropdownItem',
  components: { GlDisclosureDropdownItem },
  inject: ['namespace'],
  props: {
    member: {
      type: Object,
      required: true,
    },
  },
  methods: {
    ...mapActions({
      showLdapOverrideConfirmationModal(dispatch, payload) {
        return dispatch(`${this.namespace}/showLdapOverrideConfirmationModal`, payload);
      },
    }),
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item @action="showLdapOverrideConfirmationModal(member)">
    <template #list-item>
      <slot></slot>
    </template>
  </gl-disclosure-dropdown-item>
</template>
