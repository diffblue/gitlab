<script>
import { uniq, flatten, uniqBy } from 'lodash';
import { GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import getGroupOrProject from '../graphql/get_group_or_project.query.graphql';
import filterLabelsQueryBuilder, { LABEL_PREFIX } from '../graphql/filter_labels_query_builder';
import {
  DASHBOARD_DESCRIPTION_GROUP,
  DASHBOARD_DESCRIPTION_PROJECT,
  DASHBOARD_NAMESPACE_LOAD_ERROR,
  DASHBOARD_LABELS_LOAD_ERROR,
  METRICS_WITHOUT_LABEL_FILTERING,
} from '../constants';
import ComparisonChart from './comparison_chart.vue';
import ComparisonChartLabels from './comparison_chart_labels.vue';

export default {
  name: 'DoraVisualization',
  components: {
    ComparisonChart,
    ComparisonChartLabels,
    GlAlert,
    GlSkeletonLoader,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    data: {
      type: Object,
      required: true,
    },
  },
  apollo: {
    groupOrProject: {
      query: getGroupOrProject,
      variables() {
        return { fullPath: this.fullPath };
      },
      skip() {
        return !this.fullPath;
      },
      update(data) {
        return data;
      },
    },
    filterLabels: {
      query() {
        return filterLabelsQueryBuilder(this.rawFilterLabels, this.isProject);
      },
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      skip() {
        return this.rawFilterLabels.length === 0 || !this.namespace;
      },
      update(data) {
        const labels = Object.entries(data?.namespace || {})
          .filter(([key]) => key.includes(LABEL_PREFIX))
          .map(([, { nodes }]) => nodes);
        return uniqBy(flatten(labels), ({ id }) => id);
      },
      error() {
        // Fail silently here, an alert will be shown if there are no labels
      },
    },
  },
  data() {
    return {
      groupOrProject: null,
      filterLabels: [],
    };
  },
  computed: {
    loading() {
      return (
        this.$apollo.queries.groupOrProject.loading || this.$apollo.queries.filterLabels.loading
      );
    },
    fullPath() {
      return this.data?.namespace;
    },
    rawFilterLabels() {
      return this.data?.filter_labels || [];
    },
    hasFilterLabels() {
      return this.filterLabels.length > 0;
    },
    filterLabelNames() {
      return this.filterLabels.map(({ title }) => title);
    },
    excludeMetrics() {
      let metrics = this.data?.exclude_metrics || [];
      if (this.hasFilterLabels) {
        metrics = [...metrics, ...METRICS_WITHOUT_LABEL_FILTERING];
      }
      return uniq(metrics);
    },
    namespace() {
      return this.groupOrProject?.group || this.groupOrProject?.project;
    },
    isProject() {
      // eslint-disable-next-line no-underscore-dangle
      return this.namespace?.__typename === TYPENAME_PROJECT;
    },
    defaultTitle() {
      const name = this.namespace?.name;
      const text = this.isProject ? DASHBOARD_DESCRIPTION_PROJECT : DASHBOARD_DESCRIPTION_GROUP;
      return sprintf(text, { name });
    },
    loadNamespaceError() {
      if (this.namespace) return '';

      const { fullPath } = this;
      return sprintf(DASHBOARD_NAMESPACE_LOAD_ERROR, { fullPath });
    },
    loadLabelsError() {
      if (this.rawFilterLabels.length === 0 || this.filterLabels.length > 0) return '';

      const labels = this.rawFilterLabels.join(', ');
      return sprintf(DASHBOARD_LABELS_LOAD_ERROR, { labels });
    },
  },
};
</script>
<template>
  <div v-if="loading">
    <gl-skeleton-loader :lines="1" />
  </div>
  <gl-alert
    v-else-if="loadNamespaceError"
    class="gl-mt-5"
    variant="danger"
    :dismissible="false"
    data-testid="load-namespace-error"
  >
    {{ loadNamespaceError }}
  </gl-alert>
  <div v-else>
    <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
      <h5 data-testid="comparison-chart-title">{{ title || defaultTitle }}</h5>
      <comparison-chart-labels
        v-if="hasFilterLabels"
        :labels="filterLabels"
        :web-url="namespace.webUrl"
      />
    </div>

    <gl-alert
      v-if="loadLabelsError"
      variant="danger"
      :dismissible="false"
      data-testid="load-labels-error"
    >
      {{ loadLabelsError }}
    </gl-alert>
    <comparison-chart
      v-else
      :request-path="fullPath"
      :is-project="isProject"
      :exclude-metrics="excludeMetrics"
      :filter-labels="filterLabelNames"
    />
  </div>
</template>
