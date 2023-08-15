<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';

export default {
  name: 'DisableTwoFactorDropdownItem',
  components: { GlDisclosureDropdownItem },
  inject: ['namespace'],
  props: {
    modalMessage: {
      type: String,
      required: true,
    },
    userId: {
      type: Number,
      required: true,
    },
  },
  computed: {
    modalData() {
      return {
        message: this.modalMessage,
        userId: this.userId,
      };
    },
  },
  methods: {
    ...mapActions({
      showDisableTwoFactorModal(dispatch, payload) {
        return dispatch(`${this.namespace}/showDisableTwoFactorModal`, payload);
      },
    }),
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item @action="showDisableTwoFactorModal(modalData)">
    <template #list-item>
      <slot></slot>
    </template>
  </gl-disclosure-dropdown-item>
</template>
