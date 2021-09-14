<script>
import { GlAlert, GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import produce from 'immer';
import vulnerabilitiesQuery from 'ee/security_dashboard/graphql/queries/instance_vulnerabilities.query.graphql';
import { preparePageInfo } from 'ee/security_dashboard/helpers';
import { VULNERABILITIES_PER_PAGE } from 'ee/security_dashboard/store/constants';
import { fetchPolicies } from '~/lib/graphql';
import VulnerabilityList from '../shared/vulnerability_list.vue';

export default {
  components: {
    GlAlert,
    GlIntersectionObserver,
    GlLoadingIcon,
    VulnerabilityList,
  },
  inject: {
    canViewFalsePositive: {
      default: false,
    },
  },
  props: {
    filters: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      pageInfo: {},
      vulnerabilities: [],
      errorLoadingVulnerabilities: false,
      sortBy: 'severity',
      sortDirection: 'desc',
    };
  },
  computed: {
    isLoadingQuery() {
      return this.$apollo.queries.vulnerabilities.loading;
    },
    isLoadingFirstResult() {
      return this.isLoadingQuery && this.vulnerabilities.length === 0;
    },
    sort() {
      return `${this.sortBy}_${this.sortDirection}`;
    },
  },
  apollo: {
    vulnerabilities: {
      query: vulnerabilitiesQuery,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      variables() {
        return {
          first: VULNERABILITIES_PER_PAGE,
          sort: this.sort,
          vetEnabled: this.canViewFalsePositive,
          ...this.filters,
        };
      },
      update: ({ vulnerabilities }) => vulnerabilities.nodes,
      result({ data }) {
        this.pageInfo = preparePageInfo(data?.vulnerabilities?.pageInfo);
      },
      error() {
        this.errorLoadingVulnerabilities = true;
      },
      skip() {
        return !this.filters;
      },
    },
  },
  watch: {
    filters() {
      // Clear out the existing vulnerabilities so that the skeleton loader is shown.
      this.vulnerabilities = [];
      this.pageInfo = {};
    },
    sort() {
      // Clear out the existing vulnerabilities so that the skeleton loader is shown.
      this.vulnerabilities = [];
    },
  },
  methods: {
    onErrorDismiss() {
      this.errorLoadingVulnerabilities = false;
    },
    fetchNextPage() {
      if (this.pageInfo.hasNextPage) {
        this.$apollo.queries.vulnerabilities.fetchMore({
          variables: { after: this.pageInfo.endCursor },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            return produce(fetchMoreResult, (draftData) => {
              draftData.vulnerabilities.nodes = [
                ...previousResult.vulnerabilities.nodes,
                ...draftData.vulnerabilities.nodes,
              ];
            });
          },
        });
      }
    },
    handleSortChange({ sortBy, sortDesc }) {
      this.sortDirection = sortDesc ? 'desc' : 'asc';
      this.sortBy = sortBy;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="errorLoadingVulnerabilities"
      class="mb-4"
      variant="danger"
      @dismiss="onErrorDismiss"
    >
      {{
        s__(
          'SecurityReports|Error fetching the vulnerability list. Please check your network connection and try again.',
        )
      }}
    </gl-alert>
    <vulnerability-list
      v-else
      :filters="filters"
      :is-loading="isLoadingFirstResult"
      :vulnerabilities="vulnerabilities"
      should-show-project-namespace
      @sort-changed="handleSortChange"
    />
    <gl-intersection-observer
      v-if="pageInfo.hasNextPage"
      class="text-center"
      @appear="fetchNextPage"
    >
      <gl-loading-icon v-if="isLoadingQuery" size="md" />
    </gl-intersection-observer>
  </div>
</template>
