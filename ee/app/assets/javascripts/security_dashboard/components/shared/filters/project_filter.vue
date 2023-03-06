<script>
import {
  GlDropdownText,
  GlLoadingIcon,
  GlIntersectionObserver,
  GlDropdown,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { escapeRegExp, xor } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { createAlert } from '~/alert';
import { convertToGraphQLIds, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import groupProjectsQuery from '../../../graphql/queries/group_projects.query.graphql';
import instanceProjectsQuery from '../../../graphql/queries/instance_projects.query.graphql';
import FilterItem from './filter_item.vue';
import QuerystringSync from './querystring_sync.vue';
import DropdownButtonText from './dropdown_button_text.vue';
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
  projects.map(({ id, name }) => ({ id: getIdFromGraphQLId(id).toString(), name }));

export default {
  components: {
    FilterItem,
    GlLoadingIcon,
    GlDropdownText,
    GlIntersectionObserver,
    GlDropdown,
    QuerystringSync,
    DropdownButtonText,
    GlSearchBoxByType,
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
    selectableProjects() {
      // When searching, clicking an item should select in place (item stays where it's at in the
      // list), so we return all the projects. When not searching, clicking an item should move it
      // to the top of the list, so we return only the unselected projects.
      return this.isSearching
        ? this.projects
        : this.projects.filter(({ id }) => !this.selected.includes(id));
    },
    isLoadingProjects() {
      return this.$apollo.queries.projects.loading;
    },
    isLoadingProjectsById() {
      return this.$apollo.queries.projectsById.loading;
    },
    isSearchTooShort() {
      return this.isSearching && this.searchTerm.length < SEARCH_TERM_MINIMUM_LENGTH;
    },
    isSearching() {
      return this.searchTerm.length > 0;
    },
    showSelectedProjectsSection() {
      return Boolean(this.selected.length) && !this.isSearching;
    },
    isMaxProjectsSelected() {
      return this.selected.length >= SELECTED_PROJECTS_MAX_COUNT;
    },
    hasNoResults() {
      return !this.isLoadingProjects && this.projects.length <= 0;
    },
    // Project IDs that we didn't fetch the project data for.
    unfetchedIds() {
      return this.selected.filter((id) => !Object.hasOwn(this.projectNames, id));
    },
    shouldShowIntersectionObserver() {
      return this.pageInfo.hasNextPage && !this.isLoadingProjects;
    },
    selectedProjectNames() {
      const projects = this.validIds.map((id) => this.projectNames[id]);
      return projects.length ? projects : [this.$options.i18n.allItemsText];
    },
    // IDs of projects that actually exist.
    validIds() {
      return this.selected.filter((id) => Boolean(this.projectNames[id]));
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
      // Wait one tick for the dropdown to open, then focus on the search box.
      await this.$nextTick();
      this.$refs.searchBox.focusInput();
    },
    highlightSearchTerm(name) {
      // Don't use the regex if there's no search term, otherwise it will wrap every character with
      // <b>, i.e. '<b>1</b><b>2</b><b>3</b>'.
      if (!this.isSearching) {
        return name;
      }
      // If the search term is "sec rep", split it into "sec|rep" so that a project with the name
      // "Security Reports" is highlighted as "SECurity REPorts".
      const terms = escapeRegExp(this.searchTerm).split(' ').join('|');
      const regex = new RegExp(`(${terms})`, 'gi');
      return name.replace(regex, '<b>$1</b>');
    },
    saveProjectNames(projects) {
      projects.forEach(({ id, name }) => this.$set(this.projectNames, id, name));
    },
    fetchNextPage() {
      this.$apollo.queries.projects.fetchMore({ variables: { after: this.pageInfo.endCursor } });
    },
    deselectAll() {
      this.selected = [];
    },
    toggleSelected(id) {
      this.selected = xor(this.validIds, [id]);
    },
  },
  i18n: {
    label: s__('SecurityReports|Project'),
    allItemsText: s__('SecurityReports|All projects'),
    enterMoreCharactersToSearch: __('Enter at least three characters to search'),
    maxProjectsSelected: s__('SecurityReports|Maximum selected projects limit reached'),
    noMatchingResults: __('No matching results'),
    loadingError: __('An error occurred while retrieving projects.'),
  },
  ALL_ID,
};
</script>

<template>
  <div>
    <querystring-sync v-model="selected" querystring-key="projectId" />
    <label class="gl-mb-2">{{ $options.i18n.label }}</label>
    <gl-dropdown
      :header-text="$options.i18n.label"
      :loading="isLoadingProjectsById"
      block
      toggle-class="gl-mb-0"
      @show="setDropdownOpened"
    >
      <template #button-text>
        <dropdown-button-text :items="selectedProjectNames" :name="$options.i18n.label" />
      </template>

      <template #header>
        <gl-search-box-by-type
          ref="searchBox"
          v-model="searchTerm"
          :placeholder="__('Search')"
          autocomplete="off"
        />
      </template>

      <template #highlighted-items>
        <template v-if="showSelectedProjectsSection">
          <filter-item
            v-for="id in validIds"
            :key="id"
            is-checked
            :text="projectNames[id]"
            :data-testid="id"
            @click="toggleSelected(id)"
          />
        </template>
      </template>

      <gl-dropdown-text v-if="isMaxProjectsSelected">
        {{ $options.i18n.maxProjectsSelected }}
      </gl-dropdown-text>
      <gl-dropdown-text v-else-if="isSearchTooShort">
        {{ $options.i18n.enterMoreCharactersToSearch }}
      </gl-dropdown-text>
      <gl-dropdown-text v-else-if="hasNoResults">
        {{ $options.i18n.noMatchingResults }}
      </gl-dropdown-text>

      <template v-else>
        <filter-item
          v-if="!isSearching"
          :is-checked="!validIds.length"
          :text="$options.i18n.allItemsText"
          :data-testid="$options.ALL_ID"
          @click="deselectAll"
        />

        <filter-item
          v-for="{ id, name } in selectableProjects"
          :key="id"
          :is-checked="validIds.includes(id)"
          :text="name"
          :data-testid="id"
          @click="toggleSelected(id)"
        >
          <div v-safe-html="highlightSearchTerm(name)"></div>
        </filter-item>

        <gl-intersection-observer v-if="shouldShowIntersectionObserver" @appear="fetchNextPage" />
        <gl-loading-icon
          v-if="pageInfo.hasNextPage"
          :class="{ 'gl-visibility-hidden': !isLoadingProjects }"
          class="gl-my-2"
        />
      </template>
    </gl-dropdown>
  </div>
</template>
