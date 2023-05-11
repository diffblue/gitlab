<script>
import { isEmpty } from 'lodash';
import { GlLink, GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import {
  DASHBOARD_TITLE,
  DASHBOARD_DESCRIPTION,
  DASHBOARD_DOCS_LINK,
  MAX_PANELS_LIMIT,
  YAML_CONFIG_LOAD_ERROR,
} from '../constants';
import { fetchYamlConfig } from '../utils';
import DoraVisualization from './dora_visualization.vue';

const pathsToPanels = (paths) => paths.map((namespace) => ({ data: { namespace } }));

export default {
  name: 'DashboardsApp',
  components: {
    GlAlert,
    GlLink,
    GlSkeletonLoader,
    DoraVisualization,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    queryPaths: {
      type: Array,
      required: false,
      default: () => [],
    },
    yamlConfigProject: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  i18n: {
    learnMore: __('Learn more'),
  },
  data: () => ({
    loading: true,
    yamlConfig: {},
    projects: [],
  }),
  computed: {
    dashboardTitle() {
      return this.yamlConfig?.title || DASHBOARD_TITLE;
    },
    dashboardDescription() {
      return this.yamlConfig?.description || DASHBOARD_DESCRIPTION;
    },
    isDefaultDescription() {
      return this.dashboardDescription === DASHBOARD_DESCRIPTION;
    },
    defaultPanels() {
      return pathsToPanels([this.fullPath]);
    },
    queryPanels() {
      return pathsToPanels(this.queryPaths);
    },
    panels() {
      let list = this.defaultPanels;
      if (!isEmpty(this.queryPanels)) {
        list = list.concat(this.queryPanels);
      } else if (!isEmpty(this.yamlConfig?.panels)) {
        list = this.yamlConfig?.panels;
      }

      // Each panel requires many requests to render, so restrict
      // the number of panels to prevent overloading the server.
      return list.slice(0, MAX_PANELS_LIMIT);
    },
    loadError() {
      if (!this.yamlConfigProject?.id || this.yamlConfig) return '';

      const { fullPath } = this.yamlConfigProject;
      return sprintf(YAML_CONFIG_LOAD_ERROR, { fullPath });
    },
  },
  async mounted() {
    this.yamlConfig = await fetchYamlConfig(this.yamlConfigProject?.id);
    this.loading = false;
  },
  DASHBOARD_DOCS_LINK,
};
</script>
<template>
  <div v-if="loading" class="gl-mt-5">
    <gl-skeleton-loader :lines="2" />
  </div>
  <div v-else>
    <gl-alert v-if="loadError" class="gl-mt-5" variant="warning" :dismissible="false">
      {{ loadError }}
    </gl-alert>

    <h3 class="page-title" data-testid="dashboard-title">{{ dashboardTitle }}</h3>
    <p data-testid="dashboard-description">
      {{ dashboardDescription }}
      <gl-link v-if="isDefaultDescription" :href="$options.DASHBOARD_DOCS_LINK" target="_blank">
        {{ $options.i18n.learnMore }}.
      </gl-link>
    </p>

    <dora-visualization
      v-for="({ title, data }, index) in panels"
      :key="index"
      :title="title"
      :data="data"
    />
  </div>
</template>
