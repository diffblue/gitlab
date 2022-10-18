<script>
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import { s__ } from '~/locale';

export default {
  name: 'AnalyticsDashboard',
  components: {
    CustomizableDashboard,
  },
  data() {
    return {
      widgets: [
        {
          component: 'CubeLineChart',
          title: s__('ProductAnalytics|Audience'),
          gridAttributes: {
            size: {
              width: 3,
              height: 3,
            },
          },
        },
      ],
    };
  },
};
</script>

<template>
  <customizable-dashboard :widgets="widgets" :editable="false" />
</template>
