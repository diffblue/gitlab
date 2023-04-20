<script>
import { debounce, isString } from 'lodash';
import { GlCollapsibleListbox, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { logError } from '~/lib/logger';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import searchProjectsQuery from '../../graphql/queries/search_projects.query.graphql';

export const i18n = {
  searchPlaceholder: __('Search projects'),
  noResultsMessage: __('No results'),
  emptyFieldPlaceholder: __('Select a project'),
  searchFailedMessage: __('Something went wrong while fetching projects.'),
  dropdownHeader: __('Select a project'),
};

export const PROJECTS_MAX_LIMIT = 20;

/* TODO: Consider creating a follow-up issue to convert this into a
 * vue_shared reusable component.
 * Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/407360
 */
export default {
  components: {
    GlCollapsibleListbox,
    GlIcon,
  },
  props: {
    value: {
      type: Object,
      required: false,
      default: null,
      validator: (value) => {
        return !value || (isString(value.fullPath) && isString(value.nameWithNamespace));
      },
    },
  },
  apollo: {
    projects: {
      query: searchProjectsQuery,
      variables() {
        return {
          search: this.searchProjectsTerm,
          first: PROJECTS_MAX_LIMIT,
          sort: 'similarity',
        };
      },
      result({ data, error }) {
        if (error) {
          return;
        }

        const { nodes: projects } = data.projects;

        this.searchProjectsFailed = false;
        this.searchProjectsResult = projects.map((project) => ({
          text: project.nameWithNamespace,
          value: project.fullPath,
          project,
        }));
      },
      error(error) {
        logError(error);
        this.searchProjectsFailed = true;
      },
    },
  },
  data() {
    return {
      searchProjectsTerm: '',
      searchProjectsResult: [],
      searchProjectsFailed: false,
    };
  },
  computed: {
    isSearchingProjects() {
      return this.$apollo.queries.projects?.loading;
    },
    projectSelectorToggleText() {
      return this.value ? this.value.nameWithNamespace : i18n.emptyFieldPlaceholder;
    },
    listBoxSelectedValue() {
      return this.value?.fullPath;
    },
  },
  created() {
    this.searchProjectDebounced = debounce(this.searchProject, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    selectProject(value) {
      const selectedProject = this.searchProjectsResult.find(
        (searchResult) => searchResult.value === value,
      )?.project;

      if (selectedProject) {
        this.$emit('input', selectedProject);
      }
    },
    searchProject(searchTerm) {
      this.searchProjectsTerm = searchTerm;
    },
  },
  i18n,
};
</script>
<template>
  <gl-collapsible-listbox
    class="gl-w-full"
    block
    searchable
    :selected="listBoxSelectedValue"
    :items="searchProjectsResult"
    :searching="isSearchingProjects"
    :header-text="$options.i18n.dropdownHeader"
    :no-results-text="$options.i18n.noResultsMessage"
    :search-placeholder="$options.i18n.searchPlaceholder"
    :toggle-text="projectSelectorToggleText"
    @search="searchProjectDebounced"
    @select="selectProject"
  >
    <template #list-item="{ item }">
      {{ item.text }}
    </template>
    <template #footer>
      <div
        v-if="searchProjectsFailed"
        data-testid="red-selector-error-list"
        class="gl-display-flex gl-align-items-flex-start gl-text-red-500 gl-mx-4 gl-my-3"
      >
        <gl-icon name="error" class="gl-mr-2 gl-mt-2 gl-flex-shrink-0" />
        <span>{{ $options.i18n.searchFailedMessage }}</span>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
