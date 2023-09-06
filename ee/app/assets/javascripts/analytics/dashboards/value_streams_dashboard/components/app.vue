<script>
import { isEmpty } from 'lodash';
import { GlLink, GlSkeletonLoader, GlSprintf, GlAlert } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import {
  ALERT_TEXT,
  DASHBOARD_TITLE,
  DASHBOARD_DESCRIPTION,
  DASHBOARD_SURVEY_LINK,
  DASHBOARD_DOCS_LINK,
  MAX_PANELS_LIMIT,
  YAML_CONFIG_LOAD_ERROR,
} from '../../constants';
import { fetchYamlConfig } from '../../yaml_utils';
import DoraVisualization from '../../components/dora_visualization.vue';
import DoraPerformersScore from '../../components/dora_performers_score.vue';

const pathsToPanels = (paths) =>
  paths.map(({ namespace, isProject = false }) => ({ data: { namespace }, isProject }));

export default {
  name: 'DashboardsApp',
  components: {
    GlAlert,
    GlLink,
    GlSkeletonLoader,
    GlSprintf,
    DoraVisualization,
    DoraPerformersScore,
    UserCalloutDismisser,
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
    alertText: ALERT_TEXT,
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
      return pathsToPanels([{ namespace: this.fullPath }]);
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
    groupPanels() {
      return this.panels.filter(({ isProject }) => !isProject);
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
  DASHBOARD_SURVEY_LINK,
};
</script>
<template>
  <div>
    <user-callout-dismisser feature-name="vsd_feedback_banner">
      <template #default="{ dismiss, shouldShowCallout }">
        <gl-alert v-if="shouldShowCallout" data-testid="alert-banner" @dismiss="dismiss">
          <gl-sprintf :message="$options.i18n.alertText">
            <template #link="{ content }">
              <gl-link :href="$options.DASHBOARD_SURVEY_LINK">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </gl-alert>
      </template>
    </user-callout-dismisser>
    <div v-if="loading" class="gl-mt-5">
      <gl-skeleton-loader :lines="2" />
    </div>
    <div v-else>
      <gl-alert
        v-if="loadError"
        data-testid="alert-error"
        class="gl-mt-5"
        variant="warning"
        :dismissible="false"
      >
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

      <dora-performers-score
        v-for="({ data }, index) in groupPanels"
        :key="`dora-performers-score-panel-${index}`"
        :data="data"
        class="gl-mt-5"
      />
    </div>
  </div>
</template>
