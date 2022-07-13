<script>
import { s__ } from '~/locale';

const i18n = {
  configuration: { title: s__('CloudSeed|Configuration') },
  deployments: { title: s__('CloudSeed|Deployments') },
  databases: { title: s__('CloudSeed|Databases') },
};

export default {
  props: {
    active: {
      type: String,
      required: true,
    },
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
  computed: {
    isConfigurationActive() {
      return this.active === 'configuration';
    },
    isDeploymentsActive() {
      return this.active === 'deployments';
    },
    isDatabasesActive() {
      return this.active === 'databases';
    },
  },
  i18n,
};
</script>
<template>
  <div class="tabs gl-tabs">
    <ul role="tablist" class="nav gl-tabs-nav">
      <li role="presentation" class="nav-item">
        <a
          data-testid="configurationLink"
          role="tab"
          :href="configurationUrl"
          class="nav-link gl-tab-nav-item"
          :class="{ 'gl-tab-nav-item-active': isConfigurationActive }"
        >
          {{ $options.i18n.configuration.title }}</a
        >
      </li>
      <li role="presentation" class="nav-item">
        <a
          data-testid="deploymentsLink"
          role="tab"
          :href="deploymentsUrl"
          class="nav-link gl-tab-nav-item"
          :class="{ 'gl-tab-nav-item-active': isDeploymentsActive }"
        >
          {{ $options.i18n.deployments.title }}
        </a>
      </li>
      <li role="presentation" class="nav-item">
        <a
          data-testid="databasesLink"
          role="tab"
          :href="databasesUrl"
          class="nav-link gl-tab-nav-item"
          :class="{ 'gl-tab-nav-item-active': isDatabasesActive }"
        >
          {{ $options.i18n.databases.title }}
        </a>
      </li>
    </ul>
  </div>
</template>
