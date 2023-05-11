<script>
import { GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import getGroupOrProject from '../graphql/get_group_or_project.query.graphql';
import {
  DASHBOARD_DESCRIPTION_GROUP,
  DASHBOARD_DESCRIPTION_PROJECT,
  DASHBOARD_NAMESPACE_LOAD_ERROR,
} from '../constants';
import ComparisonChart from './comparison_chart.vue';

export default {
  name: 'DoraVisualization',
  components: {
    ComparisonChart,
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
  },
  data() {
    return {
      groupOrProject: null,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.groupOrProject.loading;
    },
    fullPath() {
      return this.data?.namespace;
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
    loadError() {
      if (this.namespace) return '';

      const { fullPath } = this;
      return sprintf(DASHBOARD_NAMESPACE_LOAD_ERROR, { fullPath });
    },
  },
};
</script>
<template>
  <div v-if="loading">
    <gl-skeleton-loader :lines="1" />
  </div>
  <gl-alert v-else-if="loadError" class="gl-mt-5" variant="danger" :dismissible="false">
    {{ loadError }}
  </gl-alert>
  <div v-else>
    <h5 data-testid="comparison-chart-title">{{ title || defaultTitle }}</h5>
    <comparison-chart :request-path="fullPath" :is-project="isProject" />
  </div>
</template>
