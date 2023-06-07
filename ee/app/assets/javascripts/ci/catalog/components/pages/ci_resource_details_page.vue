<script>
import { createAlert } from '~/alert';
import getCatalogCiResourceDetails from '../../graphql/queries/get_ci_catalog_resource_details.query.graphql';
import CiResourceAbout from '../details/ci_resource_about.vue';
import CiResourceDetails from '../details/ci_resource_details.vue';
import CiResourceHeader from '../details/ci_resource_header.vue';

export default {
  components: { CiResourceAbout, CiResourceDetails, CiResourceHeader },
  data() {
    return {
      resourceDetails: {},
    };
  },
  apollo: {
    resourceDetails: {
      query: getCatalogCiResourceDetails,
      update(data) {
        return data.ciCatalogResourcesDetails.nodes[0];
      },
      error(e) {
        createAlert({ message: e.message });
      },
    },
  },
};
</script>
<template>
  <div class="gl-display-flex">
    <div class="gl-w-70p">
      <ci-resource-header
        :description="resourceDetails.description"
        :name="resourceDetails.name"
        :root-namespace="resourceDetails.rootNamespace"
      />
      <ci-resource-details :readme-html="resourceDetails.readmeHtml" />
    </div>
    <div>
      <ci-resource-about
        :statistics="resourceDetails.statistics"
        :versions="resourceDetails.versions.nodes"
      />
    </div>
  </div>
</template>
