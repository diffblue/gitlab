<script>
import { s__ } from '~/locale';
import GcpRegionsList from '../gcp_regions/list.vue';
import GoogleCloudMenu from '../components/google_cloud_menu.vue';
import IncubationBanner from '../components/incubation_banner.vue';
import RevokeOauth from '../components/revoke_oauth.vue';
import ServiceAccountsList from '../service_accounts/list.vue';

const i18n = {
  configuration: { title: s__('CloudSeed|Configuration') },
  deployments: { title: s__('CloudSeed|Deployments') },
  databases: { title: s__('CloudSeed|Databases') },
};

export default {
  components: {
    GcpRegionsList,
    GoogleCloudMenu,
    IncubationBanner,
    RevokeOauth,
    ServiceAccountsList,
  },
  i18n,
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
    serviceAccounts: {
      type: Array,
      required: true,
    },
    createServiceAccountUrl: {
      type: String,
      required: true,
    },
    emptyIllustrationUrl: {
      type: String,
      required: true,
    },
    configureGcpRegionsUrl: {
      type: String,
      required: true,
    },
    gcpRegions: {
      type: Array,
      required: true,
    },
    revokeOauthUrl: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <incubation-banner data-testid="incubation-banner" />

    <google-cloud-menu
      data-testid="google-cloud-menu"
      active="configuration"
      :configuration-url="configurationUrl"
      :deployments-url="deploymentsUrl"
      :databases-url="databasesUrl"
    />

    <service-accounts-list
      data-testid="service-accounts-list"
      class="gl-mx-4"
      :list="serviceAccounts"
      :create-url="createServiceAccountUrl"
      :empty-illustration-url="emptyIllustrationUrl"
    />

    <hr />

    <gcp-regions-list
      data-testid="gcp-regions-list"
      class="gl-mx-4"
      :empty-illustration-url="emptyIllustrationUrl"
      :create-url="configureGcpRegionsUrl"
      :list="gcpRegions"
    />

    <hr v-if="revokeOauthUrl" />

    <revoke-oauth v-if="revokeOauthUrl" data-testid="revoke-oauth" :url="revokeOauthUrl" />
  </div>
</template>
