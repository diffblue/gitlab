<script>
import { GlDropdownItem } from '@gitlab/ui';
import { mapActions } from 'vuex';

export default {
  name: 'LdapOverrideDropdownItem',
  components: { GlDropdownItem },
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
  <gl-dropdown-item @click="showLdapOverrideConfirmationModal(member)">
    <slot></slot>
  </gl-dropdown-item>
</template>
