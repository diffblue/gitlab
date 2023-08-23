<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { s__ } from '~/locale';
import { setError } from '~/boards/graphql/cache_updates';
import subgroupsQuery from '../graphql/sub_groups.query.graphql';

export default {
  name: 'GroupSelect',
  i18n: {
    headerTitle: s__(`BoardNewEpic|Groups`),
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
    GlCollapsibleListbox,
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
    selectedGroupId() {
      return this.selectedGroup?.id || '';
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
    subGroupsListBox() {
      return this.subGroups
        .filter(({ name }) => Boolean(name))
        .map(({ id, name, ...group }) => ({ value: id, text: name, ...group }));
    },
    isLoading() {
      return this.$apollo.queries.group.loading && !this.isLoadingMore;
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
  created() {
    this.debouncedSearch = debounce(this.setSearchTerm, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    setSearchTerm(term = '') {
      this.searchTerm = term.trim();
    },
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
    <gl-collapsible-listbox
      id="descendant-group-select"
      block
      fluid-width
      data-testid="project-select-dropdown"
      infinite-scroll
      searchable
      :infinite-scroll-loading="isLoading"
      :no-results-text="$options.i18n.emptySearchResult"
      :selected="selectedGroupId"
      :searching="isLoading"
      :search-placeholder="$options.i18n.searchPlaceholder"
      :header-text="$options.i18n.headerTitle"
      :items="subGroupsListBox"
      :loading="initialLoading"
      :toggle-text="selectedGroupName"
      @bottom-reached="loadMoreGroups"
      @search="debouncedSearch"
      @select="selectGroup"
    >
      <template #list-item="{ item }">
        {{ item.fullName || item.name }}
      </template>
    </gl-collapsible-listbox>
  </div>
</template>
