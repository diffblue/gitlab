<script>
import GroupSelect from '~/vue_shared/components/entity_select/group_select.vue';
import { I18N_EMPTY_TEXT_SELF_MANAGED } from '../constants';
import ListMemberRoles from './list_member_roles.vue';

export default {
  name: 'RolesAndPermissionsSelfManaged',
  components: {
    GroupSelect,
    ListMemberRoles,
  },
  data() {
    return { groupId: null };
  },
  methods: {
    updateGroup({ value }) {
      this.groupId = value;
    },
  },
  apiParams: { top_level_only: '1' },
  i18n: {
    emptyText: I18N_EMPTY_TEXT_SELF_MANAGED,
  },
};
</script>

<template>
  <div class="col">
    <group-select
      input-id="group-selector"
      input-name="group-selector"
      :api-params="$options.apiParams"
      @input="updateGroup"
    />
    <list-member-roles :group-id="groupId" :empty-text="$options.i18n.emptyText" />
  </div>
</template>
