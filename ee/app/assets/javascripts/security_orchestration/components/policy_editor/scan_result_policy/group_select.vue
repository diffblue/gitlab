<script>
import { GlAvatarLabeled, GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import searchUsersGroups from 'ee/security_orchestration/graphql/queries/get_users_groups.query.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { GROUP_TYPE } from './lib/actions';

const createGroupObject = (group) => ({
  ...group,
  text: group.fullName || group.full_name,
  value: group.value || group.id,
});

export default {
  components: {
    GlAvatarLabeled,
    GlCollapsibleListbox,
  },
  props: {
    existingApprovers: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  apollo: {
    groups: {
      query: searchUsersGroups,
      variables() {
        return {
          search: this.search,
        };
      },
      update(data) {
        return (data?.currentUser?.groups?.nodes || []).map((group) => createGroupObject(group));
      },
      debounce: DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
    },
  },
  data() {
    return {
      selectedGroups: this.existingApprovers.map((a) => createGroupObject(a)),
      search: '',
    };
  },
  computed: {
    selectedGroupsValues() {
      return this.selectedGroups.map((g) => g.value);
    },
    toggleText() {
      return this.selectedGroups.length
        ? this.selectedGroups.map((g) => g.text).join(', ')
        : s__('SecurityOrchestration|Select groups');
    },
  },
  methods: {
    createSelectedGroups(groupsIds) {
      let updatedSelectedGroups = [...this.selectedGroups];

      const isAddingGroup = this.selectedGroups.length < groupsIds.length;
      if (isAddingGroup) {
        const newGroup = this.groups.find((g) => g.value === groupsIds[groupsIds.length - 1]);
        updatedSelectedGroups.push({
          ...newGroup,
          type: GROUP_TYPE,
          id: getIdFromGraphQLId(newGroup.value),
        });
      } else {
        updatedSelectedGroups = this.selectedGroups.filter((selectedGroup) =>
          groupsIds.includes(selectedGroup.value),
        );
      }

      return updatedSelectedGroups;
    },
    handleSelectedGroup(groupsIds) {
      const updatedSelectedGroups = this.createSelectedGroups(groupsIds);

      this.selectedGroups = updatedSelectedGroups;
      this.$emit('updateSelectedApprovers', updatedSelectedGroups);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :items="groups"
    searchable
    is-check-centered
    multiple
    toggle-class="gl-max-w-26"
    :searching="$apollo.loading"
    :selected="selectedGroupsValues"
    :toggle-text="toggleText"
    @search="search = $event"
    @select="handleSelectedGroup"
  >
    <template #list-item="{ item }">
      <gl-avatar-labeled
        shape="circle"
        :size="32"
        :src="item.avatarUrl || item.avatar_url"
        :entity-name="item.text"
        :label="item.text"
        :sub-label="item.fullPath || item.full_path"
      />
    </template>
  </gl-collapsible-listbox>
</template>
