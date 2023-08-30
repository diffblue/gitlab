<script>
import { GlAvatar, GlButton, GlCollapsibleListbox, GlIcon } from '@gitlab/ui';
import { debounce } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { filterBySearchTerm } from '~/analytics/shared/utils';
import Api from '~/api';
import { __ } from '~/locale';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { DATA_REFETCH_DELAY } from '../constants';

export default {
  name: 'GroupsDropdownFilter',
  components: {
    GlButton,
    GlIcon,
    GlAvatar,
    GlCollapsibleListbox,
  },
  directives: {
    SafeHtml,
  },
  props: {
    queryParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    defaultGroup: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      loading: true,
      selectedGroup: this.defaultGroup || {},
      groups: [],
      searchTerm: '',
    };
  },
  computed: {
    selectedGroupName() {
      return this.selectedGroup.name || __('Choose a group');
    },
    selectedGroupId() {
      return this.selectedGroup?.id;
    },
    availableGroups() {
      return filterBySearchTerm(this.groups, this.searchTerm);
    },
    listBoxItems() {
      return this.availableGroups.map(({ id, full_name: fullName, ...group }) => ({
        value: id,
        text: fullName,
        ...group,
      }));
    },
  },
  mounted() {
    this.search();
  },
  methods: {
    search: debounce(function debouncedSearch() {
      this.fetchData();
    }, DATA_REFETCH_DELAY),
    setSearchTerm(value = '') {
      this.searchTerm = value.trim();
      this.search();
    },
    onSelect(groupId) {
      this.selectedGroup = this.availableGroups.find(({ id }) => id === groupId);
      this.$emit('selected', this.selectedGroup);
    },
    fetchData() {
      this.loading = true;
      return Api.groups(this.searchTerm, this.queryParams)
        .then((groups) => {
          this.groups = groups;
        })
        .finally(() => {
          this.loading = false;
        });
    },
    isGroupSelected(id) {
      return this.selectedGroupId === id;
    },
    /**
     * Formats the group's full name.
     * It renders the last part (the part after the last backslash) of a group's full name as bold text.
     * @returns String
     */
    formatGroupPath(fullName) {
      if (!fullName) {
        return '';
      }

      const parts = fullName.split('/');
      const lastPart = parts.length - 1;
      return parts
        .map((part, idx) => (idx === lastPart ? `<strong>${part.trim()}</strong>` : part.trim()))
        .join(' / ');
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <gl-collapsible-listbox
    ref="groupsDropdown"
    is-check-centered
    searchable
    toggle-class="gl-shadow-none"
    :header-text="__('Groups')"
    :items="listBoxItems"
    :loading="loading"
    :no-results-text="__('No matching results')"
    :selected="selectedGroupId"
    :searching="loading"
    @search="setSearchTerm"
    @select="onSelect"
  >
    <template #toggle>
      <gl-button>
        <div class="gl-display-flex">
          <gl-avatar
            v-if="selectedGroup.name"
            :src="selectedGroup.avatar_url"
            :entity-id="selectedGroup.id"
            :entity-name="selectedGroup.name"
            :size="16"
            :shape="$options.AVATAR_SHAPE_OPTION_RECT"
            :alt="selectedGroup.name"
            class="gl-display-inline-flex gl-vertical-align-middle gl-mr-2"
          />
          {{ selectedGroupName }}
          <gl-icon class="gl-ml-2" name="chevron-down" />
        </div>
      </gl-button>
    </template>
    <template #list-item="{ item }">
      <div class="gl-display-flex gl-align-items-center gl-gap-2">
        <gl-avatar
          class="gl-mr-2 gl-vertical-align-middle"
          :alt="item.name"
          :size="16"
          :entity-id="item.id"
          :entity-name="item.name"
          :src="item.avatar_url"
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        />
        <div v-safe-html="formatGroupPath(item.text)" class="js-group-path align-middle"></div>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
