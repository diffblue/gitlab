<script>
import { GlDropdownItem } from '@gitlab/ui';
import { mapActions } from 'vuex';

export default {
  name: 'DisableTwoFactorDropdownItem',
  components: { GlDropdownItem },
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
  <gl-dropdown-item @click="showDisableTwoFactorModal(modalData)">
    <slot></slot>
  </gl-dropdown-item>
</template>
