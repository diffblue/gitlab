<script>
import { GlCollapsibleListbox, GlAvatarLabeled } from '@gitlab/ui';
import Api from 'ee/api';
import { __ } from '~/locale';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { TYPE_USER, TYPE_GROUP } from '../constants';

function addType(type) {
  return (items) => items.map((obj) => Object.assign(obj, { type }));
}

export default {
  components: {
    GlCollapsibleListbox,
    GlAvatarLabeled,
  },
  i18n: {
    toggleText: __('Search users or groups'),
  },
  props: {
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
    namespaceId: {
      type: String,
      required: true,
    },
    skipUserIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    skipGroupIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    isInvalid: {
      type: Boolean,
      required: false,
      default: false,
    },
    namespaceType: {
      type: String,
      required: false,
      default: NAMESPACE_TYPES.PROJECT,
    },
  },
  data() {
    return {
      listboxItems: [],
      isSearching: false,
      searchString: '',
    };
  },
  methods: {
    fetchGroupsAndUsers(term) {
      const groupsAsync = this.fetchGroups(term).then(addType(TYPE_GROUP));

      const usersAsync =
        this.namespaceType === NAMESPACE_TYPES.PROJECT
          ? this.fetchProjectUsers(term).then(addType(TYPE_USER))
          : this.fetchGroupUsers(term).then(({ data }) => addType(TYPE_USER)(data));

      return Promise.all([groupsAsync, usersAsync])
        .then(([groups, users]) => groups.concat(users))
        .then((results) => ({ results }));
    },
    fetchGroups(term) {
      // Don't includeAll when search is empty. Otherwise, the user could get a lot of garbage choices.
      // https://gitlab.com/gitlab-org/gitlab/issues/11566
      const includeAll = term.trim().length > 0;

      return Api.groups(term, {
        skip_groups: this.skipGroupIds,
        all_available: includeAll,
        order_by: 'id',
      });
    },
    fetchProjectUsers(term) {
      return Api.projectUsers(this.namespaceId, term, {
        skip_users: this.skipUserIds,
      });
    },
    fetchGroupUsers(term) {
      return Api.groupMembers(this.namespaceId, {
        query: term,
        skip_users: this.skipUserIds,
      });
    },
    getItems() {
      this.isSearching = true;

      this.fetchGroupsAndUsers(this.searchString)
        .then(({ results }) => {
          this.listboxItems = results.map((result) => ({
            name: result.type === TYPE_USER ? result.name : result.full_name,
            value: `${result.type}.${result.id}`,
            subtitle: result.type === TYPE_USER ? `@${result.username}` : result.full_path,
            ...result,
          }));
        })
        .catch(() => {})
        .finally(() => {
          this.isSearching = false;
        });
    },
    onSearch(term) {
      this.searchString = term;
      this.getItems();
    },
    onSelect(selected) {
      const selectedItem = this.listboxItems.find((item) => {
        return item.value === selected;
      });
      this.$emit('input', [selectedItem]);

      this.listboxItems = this.listboxItems.filter((item) => item.value !== selected);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :items="listboxItems"
    :toggle-text="$options.i18n.toggleText"
    :no-caret="true"
    :searchable="true"
    :searching="isSearching"
    :variant="isInvalid ? 'danger' : 'default'"
    category="secondary"
    toggle-class="gl-flex-direction-column gl-align-items-stretch!"
    class="approvers-select gl-w-full"
    @shown.once="getItems"
    @search="onSearch"
    @select="onSelect"
  >
    <template #list-item="{ item }">
      <gl-avatar-labeled
        :label="item.name"
        :sub-label="item.subtitle"
        :src="item.avatar_url"
        :entity-name="item.name"
        :size="32"
      />
    </template>
  </gl-collapsible-listbox>
</template>
