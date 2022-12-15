<script>
import { DASHBOARD_TITLE } from '../constants';

import ComparisonChart from './comparison_chart.vue';

export default {
  name: 'DashboardsApp',
  components: {
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
  },
};
</script>
<template>
  <div>
    <h1 class="page-title">{{ $options.i18n.title }}</h1>
    <comparison-chart
      v-for="({ name, fullPath, isProject }, index) in chartConfigs"
      :key="index"
      :name="name"
      :request-path="fullPath"
      :is-project="isProject"
    />
  </div>
</template>
