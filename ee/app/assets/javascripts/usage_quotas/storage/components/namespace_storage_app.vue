<script>
import { GlAlert, GlLink, GlSprintf, GlButton, GlIcon, GlKeysetPagination } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { s__ } from '~/locale';
import { captureException } from '~/ci/runner/sentry_utils';
import { namespaceContainerRegistryPopoverContent } from '../constants';
import query from '../queries/namespace_storage.query.graphql';
import GetDependencyProxyTotalSizeQuery from '../queries/dependency_proxy_usage.query.graphql';
import { formatUsageSize, parseGetStorageResults } from '../utils';
import SearchAndSortBar from '../../components/search_and_sort_bar/search_and_sort_bar.vue';
import ProjectList from './project_list.vue';
import StorageInlineAlert from './storage_inline_alert.vue';
import UsageGraph from './usage_graph.vue';
import UsageStatistics from './usage_statistics.vue';
import DependencyProxyUsage from './dependency_proxy_usage.vue';
import StorageUsageStatistics from './storage_usage_statistics.vue';
import ContainerRegistryUsage from './container_registry_usage.vue';

export default {
  name: 'NamespaceStorageApp',
  components: {
    GlAlert,
    GlLink,
    GlIcon,
    GlButton,
    GlSprintf,
    UsageGraph,
    ProjectList,
    UsageStatistics,
    StorageUsageStatistics,
    StorageInlineAlert,
    GlKeysetPagination,
    DependencyProxyUsage,
    ContainerRegistryUsage,
    SearchAndSortBar,
  },
  inject: ['namespaceId', 'namespacePath', 'purchaseStorageUrl', 'helpLinks', 'defaultPerPage'],
  provide: {
    containerRegistryPopoverContent: namespaceContainerRegistryPopoverContent,
  },
  apollo: {
    namespace: {
      query,
      variables() {
        return {
          fullPath: this.namespacePath,
          searchTerm: this.searchTerm,
          withExcessStorageData: this.isAdditionalStorageFlagEnabled,
          first: this.defaultPerPage,
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
  props: {
    storageLimitEnforced: {
      type: Boolean,
      required: false,
      default: false,
    },
    isAdditionalStorageFlagEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    isFreeNamespace: {
      type: Boolean,
      required: false,
      default: false,
    },
    isPersonalNamespace: {
      type: Boolean,
      required: false,
      default: false,
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
    };
  },
  computed: {
    namespaceProjects() {
      return this.namespace?.projects?.data ?? [];
    },
    shouldUseNewStorageDesign() {
      return this.isFreeNamespace;
    },
    formattedNamespaceLimit() {
      return formatUsageSize(this.namespace.limit);
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

      if (this.firstFetch) {
        // for initial load check if the data fetch is done (isQueryLoading)
        return this.isAdditionalStorageFlagEnabled && !this.isQueryLoading;
      }
      // for all subsequent queries the storage inline alert doesn't
      // have to be re-rendered as the data from graphql will remain
      // the same.
      return this.isAdditionalStorageFlagEnabled;
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
    fetchMoreProjects(vars) {
      this.$apollo.queries.namespace.fetchMore({
        variables: {
          fullPath: this.namespacePath,
          withExcessStorageData: this.isAdditionalStorageFlagEnabled,
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
    <div v-if="isAdditionalStorageFlagEnabled && storageStatistics">
      <storage-usage-statistics
        v-if="shouldUseNewStorageDesign"
        :storage-limit-enforced="storageLimitEnforced"
        :additional-purchased-storage-size="storageStatistics.additionalPurchasedStorageSize"
        :actual-repository-size-limit="storageStatistics.actualRepositorySizeLimit"
        :total-repository-size="storageStatistics.totalRepositorySize"
        :total-repository-size-excess="storageStatistics.totalRepositorySizeExcess"
        :loading="isStorageUsageStatisticsLoading"
      />
      <usage-statistics v-else :root-storage-statistics="storageStatistics" />
    </div>
    <div v-else class="gl-py-4 gl-px-2 gl-m-0">
      <div class="gl-display-flex gl-align-items-center">
        <div class="gl-w-half" data-qa-selector="used_storage_message">
          <gl-sprintf :message="s__('UsageQuota|You used: %{usage} %{limit}')">
            <template #usage>
              <span class="gl-font-weight-bold" data-testid="total-usage">
                {{ namespace.totalUsage }}
              </span>
            </template>
            <template #limit>
              <gl-sprintf
                v-if="namespace.limit"
                :message="s__('UsageQuota|out of %{formattedLimit} of your namespace storage')"
              >
                <template #formattedLimit>
                  <span class="gl-font-weight-bold">{{ formattedNamespaceLimit }}</span>
                </template>
              </gl-sprintf>
            </template>
          </gl-sprintf>
          <gl-link
            :href="helpLinks.usageQuotas"
            target="_blank"
            :aria-label="s__('UsageQuota|Usage quotas help link')"
          >
            <gl-icon name="question" :size="12" />
          </gl-link>
        </div>
        <div class="gl-w-half gl-text-right">
          <gl-button
            v-if="purchaseStorageUrl"
            :href="purchaseStorageUrl"
            class="gl-ml-2"
            target="_blank"
            variant="confirm"
            data-testid="purchase-storage-link"
            >{{ s__('UsageQuota|Purchase more storage') }}</gl-button
          >
        </div>
      </div>
      <div v-if="namespace.rootStorageStatistics" class="gl-w-full">
        <usage-graph
          :root-storage-statistics="namespace.rootStorageStatistics"
          :limit="namespace.limit"
        />
      </div>
    </div>

    <dependency-proxy-usage
      v-if="!isPersonalNamespace"
      :dependency-proxy-total-size="dependencyProxyTotalSize"
      :loading="isDependencyProxyStorageQueryLoading"
    />
    <template v-if="namespace.rootStorageStatistics">
      <hr class="gl-my-2" />
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
