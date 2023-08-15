<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { GlButton, GlForm } from '@gitlab/ui';
import { __ } from '~/locale';
import csrf from '~/lib/utils/csrf';

export default {
  name: 'BannedActionButtons',
  csrf,
  title: __('Unban'),
  components: { GlButton, GlForm },
  inject: ['namespace'],
  props: {
    member: {
      type: Object,
      required: true,
      validator: (member) => {
        return typeof member.id === 'number';
      },
    },
    permissions: {
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
    unbanPath() {
      return this.memberPath.replace(/:id$/, `${this.member.id}/unban`);
    },
  },
};
</script>

<template>
  <gl-form v-if="permissions.canUnban" :action="unbanPath" method="post">
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <input type="hidden" name="_method" value="put" />
    <gl-button :title="$options.title" variant="confirm" type="submit">
      {{ $options.title }}
    </gl-button>
  </gl-form>
</template>
