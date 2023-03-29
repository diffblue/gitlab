<script>
import { GlAlert, GlKeysetPagination } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { s__ } from '~/locale';
import { captureException } from '~/ci/runner/sentry_utils';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import query from '../queries/namespace_storage.query.graphql';
import GetDependencyProxyTotalSizeQuery from '../queries/dependency_proxy_usage.query.graphql';
import { parseGetStorageResults } from '../utils';
import SearchAndSortBar from '../../components/search_and_sort_bar/search_and_sort_bar.vue';
import ProjectList from './project_list.vue';
import StorageInlineAlert from './storage_inline_alert.vue';
import DependencyProxyUsage from './dependency_proxy_usage.vue';
import StorageUsageStatistics from './storage_usage_statistics.vue';
import ContainerRegistryUsage from './container_registry_usage.vue';

export default {
  name: 'NamespaceStorageApp',
  components: {
    GlAlert,
    ProjectList,
    StorageUsageStatistics,
    StorageInlineAlert,
    GlKeysetPagination,
    DependencyProxyUsage,
    ContainerRegistryUsage,
    SearchAndSortBar,
  },
  inject: [
    'namespaceId',
    'namespacePath',
    'helpLinks',
    'defaultPerPage',
    'storageLimitEnforced',
    'canShowInlineAlert',
    'userNamespace',
  ],
  apollo: {
    namespace: {
      query,
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
    dependencyProxyTotalSize: {
      query: GetDependencyProxyTotalSizeQuery,
      variables() {
        return {
          fullPath: this.namespacePath,
        };
      },
      update({ group }) {
        return group?.dependencyProxyTotalSize;
      },
      error(error) {
        captureException({ error, component: this.$options.name });
      },
    },
  },
  i18n: {
    errorMessageText: s__('UsageQuota|Something went wrong while loading usage details'),
  },
  data() {
    return {
      namespace: {},
      searchTerm: '',
      firstFetch: true,
      dependencyProxyTotalSize: '',
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
        totalRepositorySize: this.namespace.rootStorageStatistics?.storageSize,
        actualRepositorySizeLimit: this.namespace.actualRepositorySizeLimit,
        totalRepositorySizeExcess: this.namespace.totalRepositorySizeExcess,
        additionalPurchasedStorageSize: this.namespace.additionalPurchasedStorageSize,
      };
    },
    isQueryLoading() {
      return this.$apollo.queries.namespace.loading;
    },
    isDependencyProxyStorageQueryLoading() {
      return this.$apollo.queries.dependencyProxyTotalSize.loading;
    },
    pageInfo() {
      return this.namespace.projects?.pageInfo ?? {};
    },
    shouldShowStorageInlineAlert() {
      if (isEmpty(this.namespace)) {
        return false;
      }

      // for initial load check if the data fetch is done (isQueryLoading)
      if (this.firstFetch && this.isQueryLoading) {
        return false;
      }

      // for all subsequent queries the storage inline alert doesn't
      // have to be re-rendered as the data from graphql will remain
      // the same.
      return this.canShowInlineAlert;
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
      {{ $options.i18n.errorMessageText }}
    </gl-alert>
    <storage-inline-alert
      v-if="shouldShowStorageInlineAlert"
      :contains-locked-projects="namespace.containsLockedProjects"
      :repository-size-excess-project-count="namespace.repositorySizeExcessProjectCount"
      :total-repository-size-excess="namespace.totalRepositorySizeExcess"
      :total-repository-size="namespace.totalRepositorySize"
      :additional-purchased-storage-size="namespace.additionalPurchasedStorageSize"
      :actual-repository-size-limit="namespace.actualRepositorySizeLimit"
    />
    <div v-if="storageStatistics">
      <storage-usage-statistics
        :storage-limit-enforced="storageLimitEnforced"
        :additional-purchased-storage-size="storageStatistics.additionalPurchasedStorageSize"
        :actual-repository-size-limit="storageStatistics.actualRepositorySizeLimit"
        :total-repository-size="storageStatistics.totalRepositorySize"
        :total-repository-size-excess="storageStatistics.totalRepositorySizeExcess"
        :loading="isStorageUsageStatisticsLoading"
      />
    </div>

    <dependency-proxy-usage
      v-if="!userNamespace"
      :dependency-proxy-total-size="dependencyProxyTotalSize"
      :loading="isDependencyProxyStorageQueryLoading"
    />
    <template v-if="namespace.rootStorageStatistics">
      <container-registry-usage
        :container-registry-size="namespace.rootStorageStatistics.containerRegistrySize"
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
