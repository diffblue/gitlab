<script>
import {
  GlIcon,
  GlLoadingIcon,
  GlAvatar,
  GlDropdown,
  GlDropdownSectionHeader,
  GlDropdownItem,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { filterBySearchTerm } from '~/analytics/shared/utils';
import Api from '~/api';
import { s__, __ } from '~/locale';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { DATA_REFETCH_DELAY } from '../constants';

export default {
  name: 'GroupsDropdownFilter',
  components: {
    GlIcon,
    GlLoadingIcon,
    GlAvatar,
    GlDropdown,
    GlDropdownSectionHeader,
    GlDropdownItem,
    GlSearchBoxByType,
  },
  directives: {
    SafeHtml,
  },
  props: {
    label: {
      type: String,
      required: false,
      default: s__('CycleAnalytics|group dropdown filter'),
    },
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
    noResultsAvailable() {
      const { loading, availableGroups } = this;
      return !loading && !availableGroups.length;
    },
  },
  watch: {
    searchTerm() {
      this.search();
    },
  },
  mounted() {
    this.search();
  },
  methods: {
    search: debounce(function debouncedSearch() {
      this.fetchData();
    }, DATA_REFETCH_DELAY),
    onClick({ group }) {
      this.selectedGroup = group;
      this.$emit('selected', this.selectedGroup);
    },
    fetchData() {
      this.loading = true;
      return Api.groups(this.searchTerm, this.queryParams).then((groups) => {
        this.loading = false;
        this.groups = groups;
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
  <gl-dropdown ref="groupsDropdown" class="dropdown dropdown-groups" toggle-class="gl-shadow-none">
    <template #button-content>
      <div class="gl-display-flex gl-flex-grow-1">
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
      </div>
      <gl-icon class="gl-ml-2" name="chevron-down" />
    </template>
    <gl-dropdown-section-header>{{ __('Groups') }}</gl-dropdown-section-header>
    <gl-search-box-by-type v-model.trim="searchTerm" />
    <gl-dropdown-item
      v-for="group in availableGroups"
      :key="group.id"
      is-check-item
      :is-checked="isGroupSelected(group.id)"
      @click.prevent="onClick({ group, isSelected: isGroupSelected(group.id) })"
    >
      <div class="gl-display-flex">
        <gl-avatar
          class="gl-mr-2 gl-vertical-align-middle"
          :alt="group.name"
          :size="16"
          :entity-id="group.id"
          :entity-name="group.name"
          :src="group.avatar_url"
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        />
        <div
          v-safe-html="formatGroupPath(group.full_name)"
          class="js-group-path align-middle"
        ></div>
      </div>
    </gl-dropdown-item>
    <gl-dropdown-item v-show="noResultsAvailable" class="gl-pointer-events-none text-secondary">{{
      __('No matching results')
    }}</gl-dropdown-item>
    <gl-dropdown-item v-if="loading">
      <gl-loading-icon size="lg" />
    </gl-dropdown-item>
  </gl-dropdown>
</template>
