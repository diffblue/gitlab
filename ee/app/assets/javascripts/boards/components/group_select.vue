<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlSearchBoxByType,
  GlIntersectionObserver,
  GlLoadingIcon,
} from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { s__ } from '~/locale';
import { featureAccessLevel } from '~/pages/projects/shared/permissions/constants';
import { ListType } from '../constants';

export default {
  name: 'GroupSelect',
  i18n: {
    headerTitle: s__(`BoardNewEpic|Groups`),
    dropdownText: s__(`BoardNewEpic|Select a group`),
    searchPlaceholder: s__(`BoardNewEpic|Search groups`),
    emptySearchResult: s__(`BoardNewEpic|No matching results`),
  },
  defaultFetchOptions: {
    with_issues_enabled: true,
    with_shared: false,
    include_subgroups: true,
    order_by: 'similarity',
  },
  components: {
    GlIntersectionObserver,
    GlLoadingIcon,
    GlDropdown,
    GlDropdownItem,
    GlDropdownText,
    GlSearchBoxByType,
  },
  inject: ['groupId'],
  props: {
    list: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      initialLoading: true,
      searchTerm: '',
    };
  },
  computed: {
    ...mapState(['subGroupsFlags', 'subGroups', 'selectedGroup']),
    selectedGroupName() {
      return this.selectedGroup.name || s__('BoardNewEpic|Loading groups');
    },
    fetchOptions() {
      const additionalAttrs = {};
      if (this.list.type && this.list.type !== ListType.backlog) {
        additionalAttrs.min_access_level = featureAccessLevel.EVERYONE;
      }

      return {
        ...this.$options.defaultFetchOptions,
        ...additionalAttrs,
      };
    },
    isFetchResultEmpty() {
      return this.subGroups.length === 0;
    },
    hasNextPage() {
      return this.subGroupsFlags.pageInfo?.hasNextPage;
    },
  },
  watch: {
    searchTerm() {
      this.fetchSubGroups({ search: this.searchTerm });
    },
  },
  async mounted() {
    await this.fetchSubGroups();

    this.initialLoading = false;
  },
  methods: {
    ...mapActions(['fetchSubGroups', 'setSelectedGroup']),
    selectGroup(groupId) {
      this.setSelectedGroup(this.subGroups.find((group) => group.id === groupId));
    },
    loadMoreGroups() {
      this.fetchSubGroups({ search: this.searchTerm, fetchNext: true });
    },
  },
};
</script>

<template>
  <div>
    <label
      for="descendant-group-select"
      class="gl-font-weight-bold gl-mt-3"
      data-testid="header-label"
      >{{ $options.i18n.headerTitle }}</label
    >
    <gl-dropdown
      id="descendant-group-select"
      data-testid="project-select-dropdown"
      :text="selectedGroupName"
      :header-text="$options.i18n.headerTitle"
      block
      menu-class="gl-w-full!"
      :loading="initialLoading"
    >
      <gl-search-box-by-type
        v-model.trim="searchTerm"
        debounce="250"
        :placeholder="$options.i18n.searchPlaceholder"
      />
      <gl-dropdown-item
        v-for="group in subGroups"
        v-show="!subGroupsFlags.isLoading"
        :key="group.id"
        :name="group.name"
        @click="selectGroup(group.id)"
      >
        {{ group.fullName }}
      </gl-dropdown-item>
      <gl-dropdown-text v-show="subGroupsFlags.isLoading" data-testid="dropdown-text-loading-icon">
        <gl-loading-icon class="gl-mx-auto" size="sm" />
      </gl-dropdown-text>
      <gl-dropdown-text
        v-if="isFetchResultEmpty && !subGroupsFlags.isLoading"
        data-testid="empty-result-message"
      >
        <span class="gl-text-gray-500">{{ $options.i18n.emptySearchResult }}</span>
      </gl-dropdown-text>
      <gl-intersection-observer v-if="hasNextPage" @appear="loadMoreGroups">
        <gl-loading-icon v-if="subGroupsFlags.isLoadingMore" size="lg" />
      </gl-intersection-observer>
    </gl-dropdown>
  </div>
</template>
