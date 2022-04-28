<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { TYPE_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import MinutesUsageMonthChart from 'ee/ci_minutes_usage/components/minutes_usage_month_chart.vue';
import MinutesUsageProjectChart from 'ee/ci_minutes_usage/components/minutes_usage_project_chart.vue';
import getCiMinutesUsageGroup from '../graphql/queries/ci_minutes_namespace.query.graphql';

export default {
  components: {
    GlLoadingIcon,
    MinutesUsageMonthChart,
    MinutesUsageProjectChart,
  },
  inject: ['namespaceId'],
  data() {
    return {
      ciMinutesUsage: [],
    };
  },
  apollo: {
    ciMinutesUsage: {
      query: getCiMinutesUsageGroup,
      variables() {
        return {
          namespaceId: convertToGraphQLId(TYPE_GROUP, this.namespaceId),
        };
      },
      update(res) {
        return res?.ciMinutesUsage?.nodes;
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.ciMinutesUsage.loading;
    },
    borderStyles() {
      return 'gl-border-b-solid gl-border-gray-200 gl-border-b-1';
    },
  },
};
</script>
<template>
  <div :class="borderStyles" class="gl-my-7">
    <gl-loading-icon v-if="loading" size="md" class="gl-mb-5" />
    <template v-else>
      <minutes-usage-month-chart :class="borderStyles" :ci-minutes-usage="ciMinutesUsage" />
      <minutes-usage-project-chart :minutes-usage-data="ciMinutesUsage" />
    </template>
  </div>
</template>
