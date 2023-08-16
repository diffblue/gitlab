<script>
import { GlAvatar, GlCollapsibleListbox, GlTruncate, GlTooltipDirective } from '@gitlab/ui';
import produce from 'immer';
import { __ } from '~/locale';
import getUsersProjects from '~/graphql_shared/queries/get_users_projects.query.graphql';
import { PAGE_SIZE } from 'ee/security_orchestration/constants';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

const defaultPageInfo = { endCursor: '', hasNextPage: false };

export default {
  AVATAR_SHAPE_OPTION_RECT,
  MINIMUM_QUERY_LENGTH: 3,
  SEARCH_ERROR: 'SEARCH_ERROR',
  QUERY_TOO_SHORT_ERROR: 'QUERY_TOO_SHORT_ERROR',
  NO_RESULTS_ERROR: 'NO_RESULTS_ERROR',
  i18n: {
    defaultPlaceholder: __('Select a project'),
    errorNetworkMessage: __('Something went wrong, unable to search projects'),
    noResultsText: __('Sorry, no projects matched your search'),
    searchText: __('Enter at least three characters to search'),
  },
  apollo: {
    projects: {
      query: getUsersProjects,
      variables() {
        return {
          search: this.searchQuery,
          first: PAGE_SIZE,
          searchNamespaces: true,
          sort: 'similarity',
        };
      },
      update(data) {
        return data?.projects?.nodes || [];
      },
      result({ data }) {
        const projects = data?.projects || {};

        this.pageInfo = projects.pageInfo || defaultPageInfo;

        if (projects.nodes?.length === 0) {
          this.setErrorType(this.$options.NO_RESULTS_ERROR);
        }
      },
      error() {
        this.fetchProjectsError();
      },
      skip() {
        return this.isSearchQueryTooShort;
      },
    },
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlAvatar,
    GlCollapsibleListbox,
    GlTruncate,
  },
  props: {
    headerText: {
      type: String,
      required: false,
      default: __('Select a project'),
    },
    selectedProject: {
      type: Object,
      required: false,
      default: null,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      errorType: null,
      projects: [],
      searchQuery: '',
      pageInfo: defaultPageInfo,
    };
  },
  computed: {
    isSearchingProjects() {
      return this.$apollo.queries.projects.loading;
    },
    isLoadingFirstResult() {
      return this.isSearchingProjects && this.projects.length === 0;
    },
    isSearchQueryTooShort() {
      return this.searchQuery.length < this.$options.MINIMUM_QUERY_LENGTH;
    },
    selected() {
      return this.selectedProject?.id || '';
    },
    toggleText() {
      return this.selectedProject?.name || this.$options.i18n.defaultPlaceholder;
    },
    listBoxItems() {
      return this.projects.map(({ id, name, ...project }) => ({
        ...project,
        value: id,
        text: name,
      }));
    },
    searchSuggestionText() {
      return this.isSearchQueryTooShort
        ? this.$options.i18n.searchText
        : this.$options.i18n.noResultsText;
    },
  },
  methods: {
    cancelSearch() {
      this.projects = [];
      this.pageInfo = defaultPageInfo;
      this.setErrorType(this.$options.QUERY_TOO_SHORT_ERROR);
    },
    fetchNextPage() {
      if (this.pageInfo.hasNextPage) {
        this.$apollo.queries.projects.fetchMore({
          variables: { after: this.pageInfo.endCursor },
          // Transform the previous result with new data
          updateQuery: (previousResult, { fetchMoreResult }) => {
            return produce(fetchMoreResult, (draftData) => {
              draftData.projects.nodes = [
                ...previousResult.projects.nodes,
                ...draftData.projects.nodes,
              ];
            });
          },
        });
      }
    },
    fetchProjects(query) {
      this.searchQuery = query;

      if (this.isSearchQueryTooShort) {
        this.cancelSearch();
      } else {
        this.errorType = null;
        this.pageInfo = defaultPageInfo;
        this.projects = [];
      }
    },
    fetchProjectsError() {
      this.projects = [];
      this.setErrorType(this.$options.SEARCH_ERROR);
    },
    isErrorOfType(type) {
      return this.errorType === type;
    },
    setErrorType(errorType) {
      this.errorType = errorType;
    },
    selectProject(projectId) {
      const project = this.projects.find(({ id }) => projectId === id);
      this.$emit('projectClicked', project);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    block
    fluid-width
    searchable
    infinite-scroll
    is-check-centered
    :disabled="disabled"
    :header-text="headerText"
    :loading="isLoadingFirstResult"
    :no-results-text="searchSuggestionText"
    :searching="isSearchingProjects"
    :selected="selected"
    :items="listBoxItems"
    :toggle-text="toggleText"
    @bottom-reached="fetchNextPage"
    @search="fetchProjects"
    @select="selectProject"
  >
    <template #list-item="{ item }">
      <div class="gl-display-flex gl-flex-nowrap gl-gap-3 gl-align-items-center">
        <gl-avatar
          fallback-on-error
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
          :entity-name="item.text"
          :alt="item.text"
          :src="item.text[0]"
          :size="32"
        />
        <gl-truncate :text="item.nameWithNamespace" with-tooltip />
      </div>
    </template>
    <template #footer>
      <div
        v-if="isErrorOfType($options.SEARCH_ERROR)"
        data-testid="error-message"
        class="gl-text-red-500 gl-pl-7 gl-pr-3 gl-pb-3 js-search-error-message"
      >
        {{ $options.i18n.errorNetworkMessage }}
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
