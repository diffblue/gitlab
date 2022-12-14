<script>
import {
  GlDropdownDivider,
  GlDropdownText,
  GlLoadingIcon,
  GlIntersectionObserver,
} from '@gitlab/ui';
import { escapeRegExp, has, xorBy } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { createAlert } from '~/flash';
import { convertToGraphQLIds, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import groupProjectsQuery from '../../../graphql/queries/group_projects.query.graphql';
import instanceProjectsQuery from '../../../graphql/queries/instance_projects.query.graphql';
import { PROJECT_LOADING_ERROR_MESSAGE } from '../../../helpers';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';
import SimpleFilter from './simple_filter.vue';

const SEARCH_TERM_MINIMUM_LENGTH = 3;
const SELECTED_PROJECTS_MAX_COUNT = 100;
const PROJECT_ENTITY_NAME = 'Project';

const mapProjects = (projects = []) =>
  projects.map((p) => ({ id: getIdFromGraphQLId(p.id).toString(), name: p.name }));

export default {
  name: 'ProjectFilter',
  components: {
    FilterBody,
    FilterItem,
    GlDropdownDivider,
    GlLoadingIcon,
    GlDropdownText,
    GlIntersectionObserver,
  },
  directives: { SafeHtml },
  extends: SimpleFilter,
  inject: ['groupFullPath', 'dashboardType'],
  data: () => ({
    projectsCache: {},
    projects: [],
    pageInfo: { hasNextPage: true },
    searchTerm: '',
    hasDropdownBeenOpened: false,
  }),
  computed: {
    options() {
      // Return the projects that exist.
      return Object.values(this.projectsCache).filter(Boolean);
    },
    selectedSet() {
      return new Set(this.selectedOptions.map((x) => x.id));
    },
    selectableProjects() {
      // When searching, we want the "select in place" behavior when a dropdown item is clicked, so
      // we show all the projects. If not, we want the "move the selected item to the top" behavior,
      // so we show only unselected projects:
      return this.isSearching ? this.projects : this.projects.filter((x) => !this.isSelected(x.id));
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
      return Boolean(this.selectedOptions?.length) && !this.isSearching;
    },
    isMaxProjectsSelected() {
      return this.selectedOptions?.length >= SELECTED_PROJECTS_MAX_COUNT;
    },
    hasNoResults() {
      return !this.isLoadingProjects && this.projects.length <= 0;
    },
    uncachedIds() {
      const ids = this.querystringIds.includes(this.filter.allOption.id) ? [] : this.querystringIds;
      return ids.filter((id) => !has(this.projectsCache, id));
    },
    query() {
      return this.dashboardType === DASHBOARD_TYPES.GROUP
        ? groupProjectsQuery
        : instanceProjectsQuery;
    },
    shouldShowIntersectionObserver() {
      return this.pageInfo.hasNextPage && !this.isLoadingProjects;
    },
  },
  apollo: {
    // Gets the projects from the project IDs in the querystring and adds them to the cache.
    projectsById: {
      query() {
        return this.query;
      },
      manual: true,
      variables() {
        return {
          fullPath: this.groupFullPath,
          pageSize: SELECTED_PROJECTS_MAX_COUNT,
          // The IDs have to be in the format "gid://gitlab/Project/${projectId}"
          ids: convertToGraphQLIds(PROJECT_ENTITY_NAME, this.uncachedIds),
        };
      },
      result({ data }) {
        // Add an entry to the cache for each uncached ID. We need to do this because the backend
        // won't return a record for invalid IDs, so we need to record which IDs were queried for.
        this.uncachedIds.forEach((id) => {
          this.$set(this.projectsCache, id, undefined);
        });

        const projects = mapProjects(data[this.dashboardType].projects.edges.map((x) => x.node));
        this.saveProjectsToCache(projects);
        // Now that we have the project for each uncached ID, set the selected options.
        this.selectedOptions = this.querystringOptions;
      },
      error() {
        createAlert({ message: PROJECT_LOADING_ERROR_MESSAGE });
      },
      skip() {
        // Skip if we've already cached all the projects for every querystring ID.
        return !this.uncachedIds.length;
      },
    },
    // Gets the projects for the group with an optional search, to show as dropdown options.
    projects: {
      query() {
        return this.query;
      },
      variables() {
        return {
          fullPath: this.groupFullPath,
          search: this.searchTerm,
        };
      },
      update(data) {
        const { projects } = data[this.dashboardType];
        this.pageInfo = projects.pageInfo;
        return mapProjects(projects.edges.map((x) => x.node));
      },
      result() {
        this.saveProjectsToCache(this.projects);
      },
      error() {
        createAlert({ message: PROJECT_LOADING_ERROR_MESSAGE });
      },
      skip() {
        return !this.hasDropdownBeenOpened || this.isSearchTooShort || this.isMaxProjectsSelected;
      },
    },
  },
  watch: {
    searchTerm() {
      // Reset the data state so that the projects query will load the first page of results.
      this.projects = [];
      this.pageInfo = { hasNextPage: true };
    },
  },
  methods: {
    processQuerystringIds() {
      if (this.uncachedIds.length) {
        this.emitFilterChanged({ [this.filter.id]: this.querystringIds });
      } else {
        this.selectedOptions = this.querystringOptions;
      }
    },
    toggleOption(option) {
      // Toggle the option's existence in the array.
      this.selectedOptions = xorBy(this.selectedOptions, [option], (x) => x.id);
      this.updateQuerystring();
    },
    setDropdownOpened() {
      this.hasDropdownBeenOpened = true;
    },
    highlightSearchTerm(name) {
      // If we use the regex with no search term, it will wrap every character with <b>, i.e.
      // '<b>1</b><b>2</b><b>3</b>'.
      if (!this.isSearching) {
        return name;
      }
      // If the search term is "sec rep", split it into "sec|rep" so that a project with the name
      // "Security Reports" is highlighted as "SECurity REPorts".
      const terms = escapeRegExp(this.searchTerm).split(' ').join('|');
      const regex = new RegExp(`(${terms})`, 'gi');
      return name.replace(regex, '<b>$1</b>');
    },
    saveProjectsToCache(projects) {
      projects.forEach((project) => this.$set(this.projectsCache, project.id, project));
    },
    fetchNextPage() {
      this.$apollo.queries.projects.fetchMore({ variables: { after: this.pageInfo.endCursor } });
    },
  },
  i18n: {
    enterMoreCharactersToSearch: __('Enter at least three characters to search'),
    maxProjectsSelected: s__('SecurityReports|Maximum selected projects limit reached'),
    noMatchingResults: __('No matching results'),
  },
};
</script>

<template>
  <filter-body
    v-model.trim="searchTerm"
    :name="filter.name"
    :selected-options="selectedOptionsOrAll"
    :show-search-box="true"
    :loading="isLoadingProjectsById"
    @dropdown-show="setDropdownOpened"
  >
    <div v-if="showSelectedProjectsSection" data-testid="selected-projects-section">
      <filter-item
        v-for="project in selectedOptions"
        :key="project.id"
        is-checked
        :text="project.name"
        @click="toggleOption(project)"
      />

      <gl-dropdown-divider />
    </div>

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
        :is-checked="isNoOptionsSelected"
        :text="filter.allOption.name"
        data-testid="allOption"
        @click="deselectAllOptions"
      />

      <filter-item
        v-for="project in selectableProjects"
        :key="project.id"
        :is-checked="isSelected(project.id)"
        :text="project.name"
        @click="toggleOption(project)"
      >
        <div v-safe-html="highlightSearchTerm(project.name)"></div>
      </filter-item>
      <gl-intersection-observer v-if="shouldShowIntersectionObserver" @appear="fetchNextPage" />
      <gl-loading-icon
        v-if="pageInfo.hasNextPage"
        :class="{ 'gl-visibility-hidden': !isLoadingProjects }"
        class="gl-my-2"
      />
    </template>
  </filter-body>
</template>
