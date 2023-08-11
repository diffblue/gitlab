<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlSearchBoxByType,
  GlIntersectionObserver,
  GlLoadingIcon,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { setError } from '~/boards/graphql/cache_updates';
import subgroupsQuery from '../graphql/sub_groups.query.graphql';

export default {
  name: 'GroupSelect',
  i18n: {
    headerTitle: s__(`BoardNewEpic|Groups`),
    dropdownText: s__(`BoardNewEpic|Select a group`),
    searchPlaceholder: s__(`BoardNewEpic|Search groups`),
    emptySearchResult: s__(`BoardNewEpic|No matching results`),
    errorFetchingGroups: s__('Boards|An error occurred while fetching groups. Please try again.'),
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
  inject: ['groupId', 'fullPath'],
  model: {
    prop: 'selectedGroup',
    event: 'selectGroup',
  },
  props: {
    list: {
      type: Object,
      required: true,
    },
    selectedGroup: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      initialLoading: true,
      isLoadingMore: false,
      searchTerm: '',
      group: {},
    };
  },
  apollo: {
    group: {
      query: subgroupsQuery,
      variables() {
        return {
          search: this.searchTerm,
          fullPath: this.fullPath,
        };
      },
      result({ data }) {
        this.initialLoading = false;
        this.selectGroup(data.group.id);
      },
      error(error) {
        setError({
          error,
          message: this.$options.i18n.errorFetchingGroups,
        });
      },
    },
  },
  computed: {
    selectedGroupName() {
      return this.selectedGroup.name || s__('BoardNewEpic|Loading groups');
    },
    currentGroup() {
      const { id, name, fullName, __typename } = this.group;
      return {
        __typename,
        id,
        name,
        fullName,
        fullPath: this.group.fullPath,
      };
    },
    subGroups() {
      const subgroups = this.group.descendantGroups?.nodes || [];
      return [this.currentGroup, ...subgroups];
    },
    isLoading() {
      return this.$apollo.queries.group.loading && !this.isLoadingMore;
    },
    isFetchResultEmpty() {
      return this.subGroups.length === 0;
    },
    pageInfo() {
      return this.group.descendantGroups?.pageInfo;
    },
    hasNextPage() {
      return this.pageInfo?.hasNextPage;
    },
  },
  watch: {
    hasNextPage() {
      return this.pageInfo?.hasNextPage;
    },
  },
  methods: {
    selectGroup(groupId) {
      this.$emit(
        'selectGroup',
        this.subGroups.find((group) => group.id === groupId),
      );
    },
    async loadMoreGroups() {
      this.isLoadingMore = true;

      try {
        await this.$apollo.queries.group.fetchMore({
          variables: {
            search: this.searchTerm,
            fullPath: this.fullPath,
            after: this.pageInfo?.endCursor,
          },
        });
      } catch (error) {
        setError({
          error,
          message: this.$options.i18n.errorFetchingGroups,
        });
      } finally {
        this.isLoadingMore = false;
      }
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
        v-for="item in subGroups"
        v-show="!isLoading"
        :key="item.id"
        :name="group.name"
        @click="selectGroup(item.id)"
      >
        {{ item.fullName }}
      </gl-dropdown-item>
      <gl-dropdown-text v-show="isLoading" data-testid="dropdown-text-loading-icon">
        <gl-loading-icon class="gl-mx-auto" size="sm" />
      </gl-dropdown-text>
      <gl-dropdown-text v-if="isFetchResultEmpty && !isLoading">
        <span class="gl-text-gray-500">{{ $options.i18n.emptySearchResult }}</span>
      </gl-dropdown-text>
      <gl-intersection-observer v-if="hasNextPage" @appear="loadMoreGroups">
        <gl-loading-icon v-if="isLoadingMore" size="lg" />
      </gl-intersection-observer>
    </gl-dropdown>
  </div>
</template>
