<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import {
  DASHBOARD_TITLE,
  DASHBOARD_FEEDBACK_INFORMATION,
  DASHBOARD_FEEDBACK_LINK,
} from '../constants';

import ComparisonChart from './comparison_chart.vue';

export default {
  name: 'DashboardsApp',
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
    ComparisonChart,
  },
  props: {
    chartConfigs: {
      type: Array,
      required: true,
    },
  },
  i18n: {
    title: DASHBOARD_TITLE,
    feedbackInformation: DASHBOARD_FEEDBACK_INFORMATION,
    feedbackLink: DASHBOARD_FEEDBACK_LINK,
  },
};
</script>
<template>
  <div>
    <h1 class="page-title">{{ $options.i18n.title }}</h1>
    <gl-alert variant="info" :dismissible="false">
      <gl-sprintf :message="$options.i18n.feedbackInformation">
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
        <template #link="{ content }">
          <gl-link :href="$options.i18n.feedbackLink" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
    <comparison-chart
      v-for="({ name, fullPath, isProject }, index) in chartConfigs"
      :key="index"
      :name="name"
      :request-path="fullPath"
      :is-project="isProject"
    />
  </div>
</template>
