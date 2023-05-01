<script>
import { debounce, isString } from 'lodash';
import { GlCollapsibleListbox, GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { logError } from '~/lib/logger';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { PROJECT_VISIBILITY } from '../../constants';
import searchProjectsQuery from '../../graphql/queries/search_projects.query.graphql';

export const i18n = {
  searchPlaceholder: __('Search%{visibility}projects'),
  searchPlaceholderWithMembership: __('Search your%{visibility}projects'),
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
    visibility: {
      type: String,
      required: false,
      default: '',
      validator: (value) => value === '' || Object.values(PROJECT_VISIBILITY).includes(value),
    },
    membership: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  apollo: {
    projects: {
      query: searchProjectsQuery,
      variables() {
        return {
          search: this.searchProjectsTerm,
          first: PROJECTS_MAX_LIMIT,
          membership: this.membership,
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
          visibility: project.visibility,
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
    filteredSearchProjectsResult() {
      return this.visibility
        ? this.searchProjectsResult.filter(({ visibility }) => visibility === this.visibility)
        : this.searchProjectsResult;
    },
    searchPlaceholder() {
      const placeholder = this.membership
        ? i18n.searchPlaceholderWithMembership
        : i18n.searchPlaceholder;

      return sprintf(placeholder, {
        visibility: this.visibility ? ` ${this.visibility} ` : ' ',
      });
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
    :items="filteredSearchProjectsResult"
    :searching="isSearchingProjects"
    :header-text="$options.i18n.dropdownHeader"
    :no-results-text="$options.i18n.noResultsMessage"
    :search-placeholder="searchPlaceholder"
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
