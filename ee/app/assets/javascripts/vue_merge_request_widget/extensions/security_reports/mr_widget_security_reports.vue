<script>
import axios from '~/lib/utils/axios_utils';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import SummaryText from './summary_text.vue';
import i18n from './i18n';

export default {
  name: 'MRSecurityWidget',
  components: {
    MrWidget,
    SummaryText,
  },
  i18n,
  inject: { mr: { default: {} } },
  data() {
    return {
      data: {
        collapsed: null,
        extended: null,
      },
    };
  },
  computed: {
    totalNewVulnerabilities() {
      return 0;
    },

    icon() {
      if (this.error) {
        return 'error-icon';
      }

      if (this.totalVulnerabilities > 0) {
        return 'warning-icon';
      }

      return 'success-icon';
    },
  },
  methods: {
    fetchExpandedData() {},

    fetchCollapsedData() {
      // TODO: check if gl.mrWidgetData can be safely removed after we migrate to the
      // widget extension.
      const endpoints = [
        [this.mr.sast_comparison_path, this.$options.i18n.sastScanner],
        [this.mr.dast_comparison_path, this.$options.i18n.dastScanner],
        [this.mr.secret_detection_comparison_path, this.$options.i18n.secretDetectionScanner],
        [this.mr.api_fuzzing_comparison_path, this.$options.i18n.apiFuzzing],
        [this.mr.coverage_fuzzing_comparison_path, this.$options.i18n.coverageFuzzing],
        [this.mr.dependency_scanning_comparison_path, this.$options.i18n.dependencyScanner],
      ];

      return endpoints.map(([path, reportType]) => () => this.fetchReport(path, reportType));
    },

    fetchReport(endpoint, reportType) {
      return axios.get(endpoint).then((r) => ({ ...r, data: { ...r.data, reportType } }));
    },
  },
};
</script>

<template>
  <mr-widget
    v-model="data"
    :loading-text="$options.i18n.loading"
    :error-text="$options.i18n.error"
    :icon="icon"
    :fetch-collapsed-data="fetchCollapsedData"
    :fetch-expanded-data="fetchExpandedData"
    multi-polling
  >
    <template #summary>
      <summary-text :total-new-vulnerabilities="totalNewVulnerabilities" />
    </template>
    <template #content>
      <!-- complex content will go here, otherwise we can use the structured :content property. -->
    </template>
  </mr-widget>
</template>
