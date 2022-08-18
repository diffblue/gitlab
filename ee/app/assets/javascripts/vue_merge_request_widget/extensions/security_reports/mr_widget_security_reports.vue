<script>
import axios from '~/lib/utils/axios_utils';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import { CRITICAL, HIGH } from '~/vulnerabilities/constants';
import SummaryText from './summary_text.vue';
import SummaryHighlights from './summary_highlights.vue';
import i18n from './i18n';

export default {
  name: 'MRSecurityWidget',
  components: {
    MrWidget,
    SummaryText,
    SummaryHighlights,
  },
  i18n,
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      vulnerabilities: {
        collapsed: null,
        extended: null,
      },
    };
  },
  computed: {
    isCollapsible() {
      if (!this.vulnerabilities.collapsed) {
        return false;
      }

      return this.vulnerabilitiesCount > 0;
    },

    vulnerabilitiesCount() {
      return this.vulnerabilities.collapsed.reduce((counter, current) => {
        return counter + (current.added?.length || 0) + (current.fixed?.length || 0);
      }, 0);
    },

    highlights() {
      if (!this.vulnerabilities.collapsed) {
        return {};
      }

      const highlights = {
        [HIGH]: 0,
        [CRITICAL]: 0,
        other: 0,
      };

      // The data we receive from the API is something like:
      // [
      //  { scanner: "SAST", added: [{ id: 15, severity: 'critical' }] },
      //  { scanner: "DAST", added: [{ id: 15, severity: 'high' }] },
      //  ...
      // ]
      return this.vulnerabilities.collapsed
        .flatMap((vuln) => vuln.added)
        .reduce((acc, vuln) => {
          if (vuln.severity === HIGH) {
            acc[HIGH] += 1;
          } else if (vuln.severity === CRITICAL) {
            acc[CRITICAL] += 1;
          } else {
            acc.other += 1;
          }
          return acc;
        }, highlights);
    },

    totalNewVulnerabilities() {
      if (!this.vulnerabilities.collapsed) {
        return 0;
      }

      return this.vulnerabilities.collapsed.reduce((counter, current) => {
        return counter + current.added.length;
      }, 0);
    },

    statusIconName() {
      if (this.totalVulnerabilities > 0) {
        return 'warning';
      }

      return 'success';
    },
  },
  methods: {
    handleIsLoading(value) {
      this.isLoading = value;
    },

    fetchExpandedData() {},

    fetchCollapsedData() {
      // TODO: check if gl.mrWidgetData can be safely removed after we migrate to the
      // widget extension.
      const endpoints = [
        [this.mr.sastComparisonPath, this.$options.i18n.sastScanner],
        [this.mr.dastComparisonPath, this.$options.i18n.dastScanner],
        [this.mr.secretDetectionComparisonPath, this.$options.i18n.secretDetectionScanner],
        [this.mr.apiFuzzingComparisonPath, this.$options.i18n.apiFuzzing],
        [this.mr.coverageFuzzingComparisonPath, this.$options.i18n.coverageFuzzing],
        [this.mr.dependencyScanningComparisonPath, this.$options.i18n.dependencyScanner],
      ].filter(([endpoint, reportType]) => Boolean(endpoint) && Boolean(reportType));

      return endpoints.map(([path, reportType]) => () =>
        axios.get(path).then((r) => ({ ...r, data: { ...r.data, reportType } })),
      );
    },
  },
};
</script>

<template>
  <mr-widget
    v-model="vulnerabilities"
    :error-text="$options.i18n.error"
    :fetch-collapsed-data="fetchCollapsedData"
    :fetch-expanded-data="fetchExpandedData"
    :status-icon-name="statusIconName"
    :widget-name="$options.name"
    :is-collapsible="isCollapsible"
    multi-polling
    @is-loading="handleIsLoading"
  >
    <template #summary>
      <summary-text :total-new-vulnerabilities="totalNewVulnerabilities" :is-loading="isLoading" />
      <summary-highlights
        v-if="!isLoading && totalNewVulnerabilities > 0"
        :highlights="highlights"
      />
    </template>
    <template #content>
      <!-- complex content will go here, otherwise we can use the structured :content property. -->
    </template>
  </mr-widget>
</template>
