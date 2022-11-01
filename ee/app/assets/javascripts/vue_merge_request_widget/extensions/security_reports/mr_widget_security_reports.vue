<script>
import { GlSprintf } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import MrWidgetRow from '~/vue_merge_request_widget/components/widget/widget_content_row.vue';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { CRITICAL, HIGH } from '~/vulnerabilities/constants';
import SummaryText from './summary_text.vue';
import SummaryHighlights from './summary_highlights.vue';
import SecurityTrainingPromoWidget from './security_training_promo_widget.vue';
import i18n from './i18n';

export default {
  name: 'WidgetSecurityReports',
  components: {
    MrWidget,
    MrWidgetRow,
    SummaryText,
    SummaryHighlights,
    SecurityTrainingPromoWidget,
    GlSprintf,
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
        expanded: null,
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
      this.vulnerabilities.collapsed.forEach((report) =>
        this.highlightsFromReport(report, highlights),
      );

      return highlights;
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
      if (this.totalNewVulnerabilities > 0) {
        return 'warning';
      }

      return 'success';
    },

    reportsWithNewVulnerabilities() {
      return this.vulnerabilities.collapsed?.filter((report) => report?.added?.length > 0) || [];
    },
  },
  methods: {
    handleIsLoading(value) {
      this.isLoading = value;
    },

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

    highlightsFromReport(report, highlights = { [HIGH]: 0, [CRITICAL]: 0, other: 0 }) {
      // The data we receive from the API is something like:
      // [
      //  { scanner: "SAST", added: [{ id: 15, severity: 'critical' }] },
      //  { scanner: "DAST", added: [{ id: 15, severity: 'high' }] },
      //  ...
      // ]
      return report.added.reduce((acc, vuln) => {
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

    statusIconNameReportType(report) {
      if (report.added?.length > 0) {
        return EXTENSION_ICONS.warning;
      }

      return EXTENSION_ICONS.success;
    },

    statusIconNameVulnerability(vuln) {
      return EXTENSION_ICONS[`severity${capitalizeFirstCharacter(vuln.severity)}`];
    },
  },
  SEVERITY_LEVELS,
};
</script>

<template>
  <mr-widget
    v-model="vulnerabilities"
    :error-text="$options.i18n.error"
    :fetch-collapsed-data="fetchCollapsedData"
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
      <security-training-promo-widget
        :security-configuration-path="mr.securityConfigurationPath"
        :project-full-path="mr.sourceProjectFullPath"
      />
      <mr-widget-row
        v-for="report in reportsWithNewVulnerabilities"
        :key="report.reportType"
        :widget-name="$options.name"
        :level="2"
        :status-icon-name="statusIconNameReportType(report)"
      >
        <template #header>
          <div :data-testid="`${report.reportType}-report-header`">
            <gl-sprintf :message="$options.i18n.newVulnerabilities">
              <template #scanner>{{ report.reportType }}</template>
              <template #number
                ><strong>{{ report.added.length }}</strong></template
              >
              <template #vulnStr>{{
                n__('vulnerability', 'vulnerabilities', report.added.length)
              }}</template>
            </gl-sprintf>
          </div>
          <summary-highlights :highlights="highlightsFromReport(report)" />
        </template>
        <template #body>
          <div class="gl-mt-2">
            <strong>{{ $options.i18n.new }}</strong>
            <div class="gl-mt-2">
              <mr-widget-row
                v-for="vuln in report.added"
                :key="vuln.uuid"
                :level="3"
                :widget-name="$options.name"
                :status-icon-name="statusIconNameVulnerability(vuln)"
              >
                <template #body>
                  {{ $options.SEVERITY_LEVELS[vuln.severity] }} {{ vuln.name }}
                </template>
              </mr-widget-row>
            </div>
          </div>
        </template>
      </mr-widget-row>
    </template>
  </mr-widget>
</template>
