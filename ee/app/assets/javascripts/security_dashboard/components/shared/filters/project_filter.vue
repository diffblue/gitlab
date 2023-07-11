<script>
import { GlCollapsibleListbox, GlLoadingIcon } from '@gitlab/ui';
import { escapeRegExp, debounce } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { createAlert } from '~/alert';
import { getSelectedOptionsText } from '~/lib/utils/listbox_helpers';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { convertToGraphQLIds, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import groupProjectsQuery from 'ee/security_dashboard/graphql/queries/group_projects.query.graphql';
import instanceProjectsQuery from 'ee/security_dashboard/graphql/queries/instance_projects.query.graphql';
import QuerystringSync from './querystring_sync.vue';
import { ALL_ID } from './constants';

const SEARCH_TERM_MINIMUM_LENGTH = 3;
const SELECTED_PROJECTS_MAX_COUNT = 100;
const PROJECT_ENTITY_NAME = 'Project';

const QUERIES = {
  [DASHBOARD_TYPES.GROUP]: groupProjectsQuery,
  [DASHBOARD_TYPES.INSTANCE]: instanceProjectsQuery,
};

// Convert the project IDs from "gid://gitlab/Project/1" to "1". It needs to be a string because
// the IDs saved on the querystring are restored as strings.
const mapProjects = (projects) =>
  projects.map(({ id, name }) => ({ value: getIdFromGraphQLId(id).toString(), text: name }));

export default {
  components: {
    GlCollapsibleListbox,
    GlLoadingIcon,
    QuerystringSync,
  },
  directives: { SafeHtml },
  inject: ['groupFullPath', 'dashboardType'],
  data: () => ({
    projectNames: {},
    projects: [],
    selected: [],
    pageInfo: { hasNextPage: true },
    searchTerm: '',
    hasDropdownBeenOpened: false,
  }),
  computed: {
    // IDs of projects that actually exist.
    validIds() {
      return this.selected.filter((value) => Boolean(this.projectNames[value]));
    },
    selectedProjects() {
      return this.validIds.map((value) => ({ value, text: this.projectNames[value] }));
    },
    unselectedProjects() {
      return this.projects.filter(({ value }) => !this.selected.includes(value));
    },
    items() {
      if (this.isMaxProjectsSelected) {
        return this.selectedProjects;
      }

      if (this.searchTerm) {
        return this.projects;
      }

      return [
        ...this.selectedProjects,
        { text: this.$options.i18n.allItemsText, value: ALL_ID },
        ...this.unselectedProjects,
      ];
    },
    selectedValues() {
      return this.validIds.length ? this.validIds : [ALL_ID];
    },
    toggleText() {
      return getSelectedOptionsText({
        options: this.selectedProjects,
        selected: this.selectedValues,
        placeholder: this.$options.i18n.allItemsText,
      });
    },
    isLoadingProjects() {
      return this.$apollo.queries.projects.loading;
    },
    isLoadingProjectsById() {
      return this.$apollo.queries.projectsById.loading;
    },
    isSearchTooShort() {
      return this.searchTerm && this.searchTerm.length < SEARCH_TERM_MINIMUM_LENGTH;
    },
    isMaxProjectsSelected() {
      return this.selected.length >= SELECTED_PROJECTS_MAX_COUNT;
    },
    // Project IDs that we didn't fetch the project data for.
    unfetchedIds() {
      return this.selected.filter((value) => !Object.hasOwn(this.projectNames, value));
    },
    hasInfiniteScroll() {
      return this.pageInfo.hasNextPage && !this.isLoadingProjects;
    },
    noResultsText() {
      const { noMatchingResults, enterMoreCharactersToSearch } = this.$options.i18n;
      if (this.isSearchTooShort) {
        return enterMoreCharactersToSearch;
      }

      return noMatchingResults;
    },
  },
  apollo: {
    // Gets the project data for the project IDs in the querystring and adds them to projectNames.
    projectsById: {
      query() {
        return QUERIES[this.dashboardType];
      },
      // This prevents the query from creating a projectsById variable on the component. The query
      // is only used to populate projectNames.
      manual: true,
      variables() {
        return {
          fullPath: this.groupFullPath,
          pageSize: SELECTED_PROJECTS_MAX_COUNT,
          // The IDs have to be in the format "gid://gitlab/Project/${projectId}"
          ids: convertToGraphQLIds(PROJECT_ENTITY_NAME, this.unfetchedIds),
        };
      },
      result({ data }) {
        // Add each unfetched ID to projectNames so that we know we fetched the project data for it.
        this.unfetchedIds.forEach((id) => {
          this.$set(this.projectNames, id, undefined);
        });

        const projects = mapProjects(data[this.dashboardType].projects.edges.map((x) => x.node));
        this.saveProjectNames(projects);
      },
      error() {
        createAlert({ message: this.$options.i18n.loadingError });
      },
      skip() {
        // Skip if we've already fetched all the projects for every project ID.
        return !this.unfetchedIds.length;
      },
    },
    // Gets the projects to show in the dropdown, with search if there's a search term.
    projects: {
      query() {
        return QUERIES[this.dashboardType];
      },
      variables() {
        return {
          fullPath: this.groupFullPath,
          search: this.searchTerm,
        };
      },
      update(data) {
        const { projects } = data[this.dashboardType];
        const mappedProjects = mapProjects(projects.edges.map((x) => x.node));
        this.saveProjectNames(mappedProjects);
        this.pageInfo = projects.pageInfo;

        return mappedProjects;
      },
      error() {
        createAlert({ message: this.$options.i18n.loadingError });
      },
      skip() {
        return !this.hasDropdownBeenOpened || this.isSearchTooShort || this.isMaxProjectsSelected;
      },
    },
  },
  watch: {
    searchTerm() {
      // When the search term is changed, clear out projects so that the old results aren't shown
      // while loading new results, and set pageInfo.hasNextPage to true so that the query will
      // run even if the previous results set it to false.
      this.projects = [];
      this.pageInfo = { hasNextPage: true };
    },
    validIds() {
      // If there are project IDs that we didn't check yet to see if they're valid, or if there's
      // at least one valid ID, use the selected IDs. Otherwise, none of the IDs are valid, so use
      // an empty array to disable the filter.
      const projectIds = this.unfetchedIds.length || this.validIds.length ? this.selected : [];

      this.$emit('filter-changed', { projectId: projectIds });
    },
  },
  methods: {
    async setDropdownOpened() {
      this.hasDropdownBeenOpened = true;
    },
    highlightSearchTerm(name) {
      // Don't use the regex if there's no search term, otherwise it will wrap every character with
      // <b>, i.e. '<b>1</b><b>2</b><b>3</b>'.
      if (!this.searchTerm) {
        return name;
      }
      // If the search term is "sec rep", split it into "sec|rep" so that a project with the name
      // "Security Reports" is highlighted as "SECurity REPorts".
      const terms = escapeRegExp(this.searchTerm).split(' ').join('|');
      const regex = new RegExp(`(${terms})`, 'gi');
      return name.replace(regex, '<b>$1</b>');
    },
    saveProjectNames(projects) {
      projects.forEach(({ value, text }) => this.$set(this.projectNames, value, text));
    },
    fetchNextPage() {
      this.$apollo.queries.projects.fetchMore({ variables: { after: this.pageInfo.endCursor } });
    },
    onSearch: debounce(function debouncedSearch(searchTerm) {
      this.searchTerm = searchTerm;
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    updateSelected(selected) {
      if (selected.at(-1) === ALL_ID) {
        this.selected = [];
      } else {
        this.selected = selected.filter((value) => value !== ALL_ID);
      }
    },
  },
  i18n: {
    searchPlaceholder: __('Search'),
    noMatchingResults: __('No matching results'),
    loadingError: __('An error occurred while retrieving projects.'),
    enterMoreCharactersToSearch: __('Enter at least three characters to search'),
    label: s__('SecurityReports|Project'),
    allItemsText: s__('SecurityReports|All projects'),
    maxProjectsSelected: s__('SecurityReports|Maximum selected projects limit reached'),
  },
  ALL_ID,
};
</script>

<template>
  <div>
    <querystring-sync v-model="selected" querystring-key="projectId" />
    <label class="gl-mb-2">{{ $options.i18n.label }}</label>
    <gl-collapsible-listbox
      :items="items"
      :selected="selectedValues"
      :toggle-text="toggleText"
      :header-text="$options.i18n.label"
      :loading="isLoadingProjectsById"
      :search-placeholder="$options.i18n.searchPlaceholder"
      :no-results-text="noResultsText"
      :infinite-scroll="hasInfiniteScroll"
      :searchable="!isMaxProjectsSelected"
      block
      multiple
      @shown="setDropdownOpened"
      @bottom-reached="fetchNextPage"
      @search="onSearch"
      @select="updateSelected"
    >
      <template #list-item="{ item }">
        <div v-safe-html="highlightSearchTerm(item.text)"></div>
      </template>
      <template v-if="isMaxProjectsSelected" #footer>
        <div class="gl-pl-7 gl-pr-5 gl-py-3 gl-text-gray-600" data-testid="max-projects-message">
          {{ $options.i18n.maxProjectsSelected }}
        </div>
      </template>
      <template v-else-if="isLoadingProjects" #footer>
        <gl-loading-icon class="gl-p-3 gl-mx-auto" />
      </template>
    </gl-collapsible-listbox>
  </div>
</template>
