<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';

export default {
  name: 'BanMemberDropdownItem',
  components: { GlDisclosureDropdownItem },
  inject: ['namespace'],
  props: {
    member: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState({
      memberPath(state) {
        return state[this.namespace].memberPath;
      },
    }),
    banPath() {
      return this.memberPath.replace(/:id$/, `${this.member.id}/ban`);
    },
    csrfToken() {
      return csrf.token;
    },
  },
  methods: {
    submitForm() {
      this.$refs.banForm.submit();
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown-item @action="submitForm">
    <template #list-item>
      <form ref="banForm" :action="banPath" method="post">
        <input :value="csrfToken" type="hidden" name="authenticity_token" />
        <input type="hidden" name="_method" value="put" />
      </form>
      <slot></slot>
    </template>
  </gl-disclosure-dropdown-item>
</template>
