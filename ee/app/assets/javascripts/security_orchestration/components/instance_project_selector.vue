<script>
import produce from 'immer';
import getUsersProjects from '~/graphql_shared/queries/get_users_projects.query.graphql';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';
import { PAGE_SIZE } from 'ee/security_orchestration/constants';

const defaultPageInfo = { endCursor: '', hasNextPage: false };

export default {
  MINIMUM_QUERY_LENGTH: 3,
  SEARCH_ERROR: 'SEARCH_ERROR',
  QUERY_TOO_SHORT_ERROR: 'QUERY_TOO_SHORT_ERROR',
  NO_RESULTS_ERROR: 'NO_RESULTS_ERROR',
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
  components: {
    ProjectSelector,
  },
  props: {
    selectedProjects: {
      type: Array,
      required: false,
      default: () => [],
    },
    maxListHeight: {
      type: Number,
      required: false,
      default: 402,
    },
    projectQuery: {
      type: Object,
      required: false,
      default: () => getUsersProjects,
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
  },
};
</script>

<template>
  <project-selector
    class="gl-w-full"
    :max-list-height="maxListHeight"
    :project-search-results="projects"
    :selected-projects="selectedProjects"
    :show-loading-indicator="isLoadingFirstResult"
    :show-minimum-search-query-message="isErrorOfType($options.QUERY_TOO_SHORT_ERROR)"
    :show-no-results-message="isErrorOfType($options.NO_RESULTS_ERROR)"
    :show-search-error-message="isErrorOfType($options.SEARCH_ERROR)"
    @searched="fetchProjects"
    @projectClicked="$emit('projectClicked', $event)"
    @bottomReached="fetchNextPage"
  />
</template>
