<script>
import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { CI_CATALOG_RESOURCE_TYPE } from '../../graphql/settings';
import getCatalogCiResourceDetails from '../../graphql/queries/get_ci_catalog_resource_details.query.graphql';
import getCatalogCiResourceSharedData from '../../graphql/queries/get_ci_catalog_resource_shared_data.query.graphql';
import CiResourceAbout from '../details/ci_resource_about.vue';
import CiResourceDetails from '../details/ci_resource_details.vue';
import CiResourceHeader from '../details/ci_resource_header.vue';
import CiResourceHeaderSkeletonLoader from '../details/ci_resource_header_skeleton_loader.vue';

export default {
  components: {
    CiResourceAbout,
    CiResourceDetails,
    CiResourceHeader,
    CiResourceHeaderSkeletonLoader,
    GlEmptyState,
    GlLoadingIcon,
  },
  inject: ['ciCatalogPath'],
  data() {
    return {
      isEmpty: false,
      resourceSharedData: {},
      resourceAdditionalDetails: {},
    };
  },
  apollo: {
    resourceSharedData: {
      query: getCatalogCiResourceSharedData,
      variables() {
        return {
          id: this.graphQLId,
        };
      },
      update(data) {
        return data.ciCatalogResource;
      },
      error(e) {
        this.isEmpty = true;
        createAlert({ message: e.message });
      },
    },
    resourceAdditionalDetails: {
      query: getCatalogCiResourceDetails,
      variables() {
        return {
          id: this.graphQLId,
        };
      },
      update(data) {
        return data.ciCatalogResource;
      },
      error(e) {
        this.isEmpty = true;
        createAlert({ message: e.message });
      },
    },
  },
  computed: {
    graphQLId() {
      return convertToGraphQLId(CI_CATALOG_RESOURCE_TYPE, this.$route.params.id);
    },
    isLoadingDetails() {
      return this.$apollo.queries.resourceAdditionalDetails.loading;
    },
    isLoadingSharedData() {
      return this.$apollo.queries.resourceSharedData.loading;
    },
    versions() {
      return this.resourceAdditionalDetails?.versions?.nodes || [];
    },
  },
  i18n: {
    emptyStateTitle: s__('CiCatalog|No component available'),
    emptyStateDescription: s__(
      'CiCatalog|Component ID not found, or you do not have permission to access component.',
    ),
    emptyStateButtonText: s__('CiCatalog|Back to the CI/CD Catalog'),
  },
};
</script>
<template>
  <div class="gl-display-flex">
    <gl-empty-state
      v-if="isEmpty"
      :title="$options.i18n.emptyStateTitle"
      :description="$options.i18n.emptyStateDescription"
      :primary-button-text="$options.i18n.emptyStateButtonText"
      :primary-button-link="ciCatalogPath"
    />
    <div v-else class="gl-display-flex">
      <div class="gl-w-70p">
        <ci-resource-header-skeleton-loader
          v-if="isLoadingSharedData"
          class="gl-pt-5 gl-border-b"
        />
        <ci-resource-header
          v-else
          :description="resourceSharedData.description"
          :icon="resourceSharedData.icon"
          :is-loading="isLoadingSharedData"
          :name="resourceSharedData.name"
          :resource-id="resourceSharedData.id"
          :root-namespace="resourceSharedData.rootNamespace"
          :web-path="resourceSharedData.webPath"
        />
        <gl-loading-icon v-if="isLoadingDetails" size="lg" class="gl-mt-5" />
        <ci-resource-details v-else :readme-html="resourceAdditionalDetails.readmeHtml" />
      </div>
      <div>
        <ci-resource-about
          :is-loading-details="isLoadingDetails"
          :is-loading-shared-data="isLoadingSharedData"
          :open-issues-count="resourceAdditionalDetails.openIssuesCount"
          :open-merge-requests-count="resourceAdditionalDetails.openMergeRequestsCount"
          :latest-version="resourceSharedData.latestVersion"
          :web-path="resourceSharedData.webPath"
        />
      </div>
    </div>
  </div>
</template>
