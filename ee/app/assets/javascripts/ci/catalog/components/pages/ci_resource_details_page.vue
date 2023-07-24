<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { CI_CATALOG_RESOURCE_TYPE } from '../../graphql/settings';
import getCatalogCiResourceDetails from '../../graphql/queries/get_ci_catalog_resource_details.query.graphql';
import CiResourceAbout from '../details/ci_resource_about.vue';
import CiResourceDetails from '../details/ci_resource_details.vue';
import CiResourceHeader from '../details/ci_resource_header.vue';

export default {
  components: { CiResourceAbout, CiResourceDetails, CiResourceHeader, GlLoadingIcon },
  data() {
    return {
      resourceDetails: {},
    };
  },
  apollo: {
    resourceDetails: {
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
        createAlert({ message: e.message });
      },
    },
  },
  computed: {
    graphQLId() {
      return convertToGraphQLId(CI_CATALOG_RESOURCE_TYPE, this.$route.params.id);
    },
    isLoading() {
      return this.$apollo.queries.resourceDetails.loading;
    },
    versions() {
      return this.resourceDetails?.versions?.nodes || [];
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" />
    <div v-else class="gl-display-flex">
      <div class="gl-w-70p">
        <ci-resource-header
          :description="resourceDetails.description"
          :icon="resourceDetails.icon"
          :name="resourceDetails.name"
          :resource-id="resourceDetails.id"
          :root-namespace="resourceDetails.rootNamespace"
          :web-path="resourceDetails.webPath"
        />
        <ci-resource-details :readme-html="resourceDetails.readmeHtml" />
      </div>
      <div>
        <ci-resource-about
          :open-issues-count="resourceDetails.openIssuesCount"
          :open-merge-requests-count="resourceDetails.openMergeRequestsCount"
          :versions="versions"
          :web-path="resourceDetails.webPath"
        />
      </div>
    </div>
  </div>
</template>
