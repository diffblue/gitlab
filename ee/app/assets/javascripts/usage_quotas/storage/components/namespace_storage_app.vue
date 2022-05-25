<script>
import {
  GlLink,
  GlSprintf,
  GlModalDirective,
  GlButton,
  GlIcon,
  GlKeysetPagination,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { parseBoolean } from '~/lib/utils/common_utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { PROJECT_TABLE_LABEL_STORAGE_USAGE } from '../constants';
import query from '../queries/namespace_storage.query.graphql';
import GetDependencyProxyTotalSizeQuery from '../queries/dependency_proxy_usage.query.graphql';
import { formatUsageSize, parseGetStorageResults } from '../utils';
import ProjectList from './project_list.vue';
import StorageInlineAlert from './storage_inline_alert.vue';
import TemporaryStorageIncreaseModal from './temporary_storage_increase_modal.vue';
import UsageGraph from './usage_graph.vue';
import UsageStatistics from './usage_statistics.vue';
import DependencyProxyUsage from './dependency_proxy_usage.vue';
import StorageUsageStatistics from './storage_usage_statistics.vue';
import ContainerRegistryUsage from './container_registry_usage.vue';

export default {
  name: 'NamespaceStorageApp',
  components: {
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
    TemporaryStorageIncreaseModal,
    DependencyProxyUsage,
    ContainerRegistryUsage,
  },
  directives: {
    GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: [
    'namespacePath',
    'purchaseStorageUrl',
    'isTemporaryStorageIncreaseVisible',
    'helpLinks',
    'defaultPerPage',
  ],
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
        Sentry.withScope((scope) => {
          scope.setTag('component', this.$options.name);
          Sentry.captureException(error);
        });
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
  },
  i18n: {
    PROJECT_TABLE_LABEL_STORAGE_USAGE,
  },
  data() {
    return {
      namespace: {},
      searchTerm: '',
      firstFetch: true,
      dependencyProxyTotalSize: '',
    };
  },
  computed: {
    namespaceProjects() {
      return this.namespace?.projects?.data ?? [];
    },
    isStorageIncreaseModalVisible() {
      return parseBoolean(this.isTemporaryStorageIncreaseVisible);
    },
    shouldUseNewStorageDesign() {
      return this.isFreeNamespace && this.glFeatures.updateStorageUsageDesign;
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
  },
  methods: {
    handleSearch(input) {
      // if length === 0 clear the search, if length > 2 update the search term
      if (input.length === 0 || input.length > 2) {
        this.searchTerm = input;
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
  modalId: 'temporary-increase-storage-modal',
};
</script>
<template>
  <div>
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
      />
      <usage-statistics v-else :root-storage-statistics="storageStatistics" />
    </div>
    <div v-else class="gl-py-4 gl-px-2 gl-m-0">
      <div class="gl-display-flex gl-align-items-center">
        <div class="gl-w-half">
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
            v-if="isStorageIncreaseModalVisible"
            v-gl-modal-directive="$options.modalId"
            category="secondary"
            variant="confirm"
            data-testid="temporary-storage-increase-button"
            >{{ s__('UsageQuota|Increase storage temporarily') }}</gl-button
          >
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
      :dependency-proxy-total-size="dependencyProxyTotalSize"
      :loading="isDependencyProxyStorageQueryLoading"
    />
    <template
      v-if="namespace.rootStorageStatistics && glFeatures.containerRegistryNamespaceStatistics"
    >
      <hr class="gl-my-2" />
      <container-registry-usage
        :container-registry-size="namespace.rootStorageStatistics.containerRegistrySize"
      />
    </template>
    <project-list
      :projects="namespaceProjects"
      :is-loading="isQueryLoading"
      :additional-purchased-storage-size="namespace.additionalPurchasedStorageSize || 0"
      :usage-label="$options.i18n.PROJECT_TABLE_LABEL_STORAGE_USAGE"
      @search="handleSearch"
    />
    <div class="gl-display-flex gl-justify-content-center gl-mt-5">
      <gl-keyset-pagination v-if="showPagination" v-bind="pageInfo" @prev="onPrev" @next="onNext" />
    </div>
    <temporary-storage-increase-modal
      v-if="isStorageIncreaseModalVisible"
      :limit="formattedNamespaceLimit"
      :modal-id="$options.modalId"
    />
  </div>
</template>
