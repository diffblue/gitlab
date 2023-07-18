<script>
import { GlAlert, GlKeysetPagination } from '@gitlab/ui';
import { captureException } from '~/ci/runner/sentry_utils';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import NamespaceStorageQuery from '../queries/namespace_storage.query.graphql';
import GetDependencyProxyTotalSizeQuery from '../queries/dependency_proxy_usage.query.graphql';
import { parseGetStorageResults } from '../utils';
import {
  NAMESPACE_STORAGE_ERROR_MESSAGE,
  NAMESPACE_STORAGE_BREAKDOWN_SUBTITLE,
} from '../constants';
import SearchAndSortBar from '../../components/search_and_sort_bar/search_and_sort_bar.vue';
import ProjectList from './project_list.vue';
import DependencyProxyUsage from './dependency_proxy_usage.vue';
import StorageUsageStatistics from './storage_usage_statistics.vue';
import ContainerRegistryUsage from './container_registry_usage.vue';

export default {
  name: 'NamespaceStorageApp',
  components: {
    GlAlert,
    ProjectList,
    StorageUsageStatistics,
    GlKeysetPagination,
    DependencyProxyUsage,
    ContainerRegistryUsage,
    SearchAndSortBar,
  },
  inject: ['namespaceId', 'namespacePath', 'helpLinks', 'defaultPerPage', 'userNamespace'],
  apollo: {
    namespace: {
      query: NamespaceStorageQuery,
      variables() {
        return {
          fullPath: this.namespacePath,
          searchTerm: this.searchTerm,
          first: this.defaultPerPage,
          sortKey: this.sortKey,
        };
      },
      update: parseGetStorageResults,
      result() {
        this.firstFetch = false;
      },
      error(error) {
        this.loadingError = true;
        captureException({ error, component: this.$options.name });
      },
    },
    dependencyProxyTotalSizeInBytes: {
      query: GetDependencyProxyTotalSizeQuery,
      variables() {
        return {
          fullPath: this.namespacePath,
        };
      },
      update({ group }) {
        return group?.dependencyProxyTotalSizeInBytes;
      },
      error(error) {
        captureException({ error, component: this.$options.name });
      },
    },
  },
  i18n: {
    NAMESPACE_STORAGE_ERROR_MESSAGE,
    NAMESPACE_STORAGE_BREAKDOWN_SUBTITLE,
  },
  data() {
    return {
      namespace: {},
      searchTerm: '',
      firstFetch: true,
      dependencyProxyTotalSizeInBytes: 0,
      loadingError: false,
      sortKey: 'STORAGE_SIZE_DESC',
    };
  },
  computed: {
    namespaceProjects() {
      return this.namespace?.projects?.data ?? [];
    },
    storageStatistics() {
      if (!this.namespace) {
        return null;
      }

      return {
        costFactoredStorageSize: this.namespace.rootStorageStatistics?.costFactoredStorageSize,
        additionalPurchasedStorageSize: this.namespace.additionalPurchasedStorageSize,
      };
    },
    isQueryLoading() {
      return this.$apollo.queries.namespace.loading;
    },
    isDependencyProxyStorageQueryLoading() {
      return this.$apollo.queries.dependencyProxyTotalSizeInBytes.loading;
    },
    pageInfo() {
      return this.namespace.projects?.pageInfo ?? {};
    },
    showPagination() {
      return Boolean(this.pageInfo?.hasPreviousPage || this.pageInfo?.hasNextPage);
    },
    isStorageUsageStatisticsLoading() {
      return this.loadingError || this.isQueryLoading;
    },
  },
  methods: {
    onSearch(searchTerm) {
      if (searchTerm?.length < 3) {
        // NOTE: currently the API doesn't handle strings of length < 3,
        // returning an empty list as a result of such searches. So here we
        // substitute short search terms with empty string to simulate default
        // "fetch all" behaviour.
        this.searchTerm = '';
      } else {
        this.searchTerm = searchTerm;
      }
    },
    onSortChanged({ sortBy, sortDesc }) {
      if (sortBy !== 'storage') {
        return;
      }

      const sortDir = sortDesc ? 'desc' : 'asc';
      const sortKey = `${convertToSnakeCase(sortBy)}_size_${sortDir}`.toUpperCase();
      this.sortKey = sortKey;
    },
    fetchMoreProjects(vars) {
      this.$apollo.queries.namespace.fetchMore({
        variables: {
          fullPath: this.namespacePath,
          ...vars,
        },
        updateQuery(previousResult, { fetchMoreResult }) {
          return fetchMoreResult;
        },
      });
    },
    onPrev(before) {
      if (this.pageInfo?.hasPreviousPage) {
        this.fetchMoreProjects({ before, last: this.defaultPerPage, first: undefined });
      }
    },
    onNext(after) {
      if (this.pageInfo?.hasNextPage) {
        this.fetchMoreProjects({ after, first: this.defaultPerPage });
      }
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="loadingError" variant="danger" :dismissible="false" class="gl-mt-4">
      {{ $options.i18n.NAMESPACE_STORAGE_ERROR_MESSAGE }}
    </gl-alert>
    <div v-if="storageStatistics">
      <storage-usage-statistics
        :additional-purchased-storage-size="storageStatistics.additionalPurchasedStorageSize"
        :used-storage="storageStatistics.costFactoredStorageSize"
        :loading="isStorageUsageStatisticsLoading"
      />
    </div>

    <h4 data-testid="breakdown-subtitle">
      {{ $options.i18n.NAMESPACE_STORAGE_BREAKDOWN_SUBTITLE }}
    </h4>

    <dependency-proxy-usage
      v-if="!userNamespace"
      :dependency-proxy-total-size="dependencyProxyTotalSizeInBytes"
      :loading="isDependencyProxyStorageQueryLoading"
    />
    <template v-if="namespace.rootStorageStatistics">
      <container-registry-usage
        :container-registry-size="namespace.rootStorageStatistics.containerRegistrySize"
        :container-registry-size-is-estimated="
          namespace.rootStorageStatistics.containerRegistrySizeIsEstimated
        "
      />
    </template>

    <section class="gl-mt-5">
      <div class="gl-bg-gray-10 gl-p-5 gl-display-flex">
        <search-and-sort-bar
          :namespace="namespaceId"
          :search-input-placeholder="s__('UsageQuota|Search')"
          @onFilter="onSearch"
        />
      </div>

      <project-list
        :projects="namespaceProjects"
        :is-loading="isQueryLoading"
        :help-links="helpLinks"
        sort-by="storage"
        :sort-desc="true"
        @sortChanged="onSortChanged($event)"
      />

      <div class="gl-display-flex gl-justify-content-center gl-mt-5">
        <gl-keyset-pagination
          v-if="showPagination"
          v-bind="pageInfo"
          @prev="onPrev"
          @next="onNext"
        />
      </div>
    </section>
  </div>
</template>
