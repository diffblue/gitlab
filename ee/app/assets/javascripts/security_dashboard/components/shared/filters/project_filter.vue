<script>
import {
  GlDropdownDivider,
  GlDropdownText,
  GlLoadingIcon,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import { escapeRegExp, has, xorBy } from 'lodash';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import createFlash from '~/flash';
import { convertToGraphQLIds } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import groupProjectsQuery from '../../../graphql/queries/group_projects.query.graphql';
import instanceProjectsQuery from '../../../graphql/queries/instance_projects.query.graphql';
import { mapProjects, PROJECT_LOADING_ERROR_MESSAGE } from '../../../helpers';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';
import SimpleFilter from './simple_filter.vue';

const SEARCH_TERM_MINIMUM_LENGTH = 3;
const SELECTED_PROJECTS_MAX_COUNT = 100;
const PROJECT_ENTITY_NAME = 'Project';

const QUERY_CONFIGS = {
  [DASHBOARD_TYPES.GROUP]: {
    query: groupProjectsQuery,
    property: 'group',
  },
  [DASHBOARD_TYPES.INSTANCE]: {
    query: instanceProjectsQuery,
    property: 'instanceSecurityDashboard',
  },
};

export default {
  components: {
    FilterBody,
    FilterItem,
    GlDropdownDivider,
    GlLoadingIcon,
    GlDropdownText,
  },
  directives: { SafeHtml },
  extends: SimpleFilter,
  inject: ['groupFullPath', 'dashboardType'],
  data: () => ({
    projectsCache: {},
    projects: [],
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
      return this.selectedOptions?.length && !this.isSearching;
    },
    showAllOption() {
      return !this.isLoadingProjects && !this.isSearching && !this.isMaxProjectsSelected;
    },
    isMaxProjectsSelected() {
      return this.selectedOptions?.length >= SELECTED_PROJECTS_MAX_COUNT;
    },
    uncachedIds() {
      const ids = this.querystringIds.includes(this.filter.allOption.id) ? [] : this.querystringIds;
      return ids.filter((id) => !has(this.projectsCache, id));
    },
    queryConfig() {
      return QUERY_CONFIGS[this.dashboardType];
    },
  },
  apollo: {
    // Gets the projects from the project IDs in the querystring and adds them to the cache.
    projectsById: {
      query() {
        return this.queryConfig.query;
      },
      manual: true,
      variables() {
        return {
          pageSize: 20,
          fullPath: this.groupFullPath,
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

        const property = data[this.queryConfig.property];
        const projects = mapProjects(property.projects.nodes);
        this.saveProjectsToCache(projects);
        // Now that we have the project for each uncached ID, set the selected options.
        this.selectedOptions = this.querystringOptions;
      },
      error() {
        createFlash({ message: PROJECT_LOADING_ERROR_MESSAGE });
      },
      skip() {
        // Skip if we've already cached all the projects for every querystring ID.
        return !this.uncachedIds.length;
      },
    },
    // Gets the projects for the group with an optional search, to show as dropdown options.
    projects: {
      query() {
        return this.queryConfig.query;
      },
      variables() {
        return {
          fullPath: this.groupFullPath,
          search: this.searchTerm,
        };
      },
      update(data) {
        const property = data[this.queryConfig.property];
        return mapProjects(property.projects.nodes);
      },
      result() {
        this.saveProjectsToCache(this.projects);
      },
      error() {
        createFlash({ message: PROJECT_LOADING_ERROR_MESSAGE });
      },
      skip() {
        return !this.hasDropdownBeenOpened || this.isSearchTooShort || this.isMaxProjectsSelected;
      },
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
        :is-checked="true"
        :text="project.name"
        @click="toggleOption(project)"
      />

      <gl-dropdown-divider />
    </div>

    <filter-item
      v-if="showAllOption"
      :is-checked="isNoOptionsSelected"
      :text="filter.allOption.name"
      data-testid="allOption"
      @click="deselectAllOptions"
    />

    <gl-loading-icon v-if="isLoadingProjects" size="md" class="gl-mt-4 gl-mb-3" />
    <gl-dropdown-text v-else-if="isMaxProjectsSelected">
      {{ $options.i18n.maxProjectsSelected }}
    </gl-dropdown-text>
    <gl-dropdown-text v-else-if="isSearchTooShort">
      {{ $options.i18n.enterMoreCharactersToSearch }}
    </gl-dropdown-text>
    <gl-dropdown-text v-else-if="!projects.length">
      {{ $options.i18n.noMatchingResults }}
    </gl-dropdown-text>
    <template v-else>
      <filter-item
        v-for="project in selectableProjects"
        :key="project.id"
        :is-checked="isSelected(project.id)"
        @click="toggleOption(project)"
      >
        <div v-safe-html="highlightSearchTerm(project.name)" class="gl-text-truncate"></div>
      </filter-item>
    </template>
  </filter-body>
</template>
