<script>
import { I18N_EMPTY_TEXT_SAAS } from '../constants';
import ListMemberRoles from './list_member_roles.vue';

export default {
  name: 'RolesAndPermissionsSaas',

  components: {
    ListMemberRoles,
  },
  props: {
    groupId: {
      type: String,
      required: true,
    },
  },
  i18n: {
    emptyText: I18N_EMPTY_TEXT_SAAS,
  },
};
</script>

<template>
  <div class="col gl-mt-5">
    <list-member-roles :group-id="groupId" :empty-text="$options.i18n.emptyText" />
  </div>
</template>
