<script>
import { GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import { DASHBOARD_TITLE, DASHBOARD_DESCRIPTION, DASHBOARD_DOCS_LINK } from '../constants';
import ComparisonChart from './comparison_chart.vue';

export default {
  name: 'DashboardsApp',
  components: {
    GlLink,
    ComparisonChart,
  },
  props: {
    chartConfigs: {
      type: Array,
      required: true,
    },
    pointerProject: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  i18n: {
    learnMore: __('Learn more'),
  },
  DASHBOARD_TITLE,
  DASHBOARD_DESCRIPTION,
  DASHBOARD_DOCS_LINK,
};
</script>
<template>
  <div>
    <h3 class="page-title">{{ $options.DASHBOARD_TITLE }}</h3>
    <p data-testid="dashboard-description">
      {{ $options.DASHBOARD_DESCRIPTION }}
      <gl-link :href="$options.DASHBOARD_DOCS_LINK" target="_blank">
        {{ $options.i18n.learnMore }}.
      </gl-link>
    </p>
    <comparison-chart
      v-for="({ name, fullPath, isProject }, index) in chartConfigs"
      :key="index"
      :name="name"
      :request-path="fullPath"
      :is-project="isProject"
    />
  </div>
</template>
