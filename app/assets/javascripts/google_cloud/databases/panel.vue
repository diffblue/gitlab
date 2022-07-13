<script>
import { s__ } from '~/locale';
import GoogleCloudMenu from '../components/google_cloud_menu.vue';
import IncubationBanner from '../components/incubation_banner.vue';

export default {
  components: {
    IncubationBanner,
    GoogleCloudMenu,
  },
  i18n: {
    configuration: { title: s__('CloudSeed|Configuration') },
    deployments: { title: s__('CloudSeed|Deployments') },
    databases: { title: s__('CloudSeed|Databases') },
  },
  props: {
    configurationUrl: {
      type: String,
      required: true,
    },
    deploymentsUrl: {
      type: String,
      required: true,
    },
    databasesUrl: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <incubation-banner />

    <google-cloud-menu
      active="databases"
      :configuration-url="configurationUrl"
      :deployments-url="deploymentsUrl"
      :databases-url="databasesUrl"
    />
  </div>
</template>
