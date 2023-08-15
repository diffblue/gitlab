<script>
import { GlListboxItem } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { s__ } from '~/locale';

export default {
  name: 'LdapDropdownFooter',
  components: {
    GlListboxItem,
  },
  inject: ['namespace'],
  props: {
    memberId: {
      type: Number,
      required: true,
    },
  },
  methods: {
    ...mapActions({
      updateLdapOverride(dispatch, payload) {
        return dispatch(`${this.namespace}/updateLdapOverride`, payload);
      },
    }),
    handleClick() {
      this.updateLdapOverride({ memberId: this.memberId, override: false })
        .then(() => {
          this.$toast.show(s__('Members|Reverted to LDAP group sync settings.'));
        })
        .catch(() => {
          // Do nothing, error handled in `updateLdapOverride` Vuex action
        });
    },
  },
};
</script>

<template>
  <ul class="gl-border-t-1 gl-border-t-solid gl-border-t-gray-200 gl-new-dropdown-contents">
    <gl-listbox-item @select="handleClick">
      {{ s__('Members|Revert to LDAP group sync settings') }}
    </gl-listbox-item>
  </ul>
</template>
