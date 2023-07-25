<script>
import { GlTab, GlTabs, GlButton, GlTooltipDirective } from '@gitlab/ui';

import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

import { ROUTE_STANDARDS_ADHERENCE, ROUTE_FRAMEWORKS, ROUTE_VIOLATIONS, TABS } from '../constants';
import MergeCommitsExportButton from './violations_report/shared/merge_commits_export_button.vue';
import ReportHeader from './shared/report_header.vue';

export default {
  name: 'ComplianceReportsApp',
  components: {
    GlTabs,
    GlTab,
    GlButton,
    MergeCommitsExportButton,
    ReportHeader,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['adherenceReportUiEnabled'],
  props: {
    mergeCommitsCsvExportPath: {
      type: String,
      required: false,
      default: '',
    },
    frameworksCsvExportPath: {
      type: String,
      required: false,
      default: '',
    },
    violationsCsvExportPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isViolationsReport() {
      return this.$route.name === ROUTE_VIOLATIONS;
    },
    isFrameworksReport() {
      return this.$route.name === ROUTE_FRAMEWORKS;
    },
    showMergeCommitsExportButton() {
      return Boolean(this.mergeCommitsCsvExportPath) && this.isViolationsReport;
    },
    showViolationsExportButton() {
      return Boolean(this.violationsCsvExportPath) && this.isViolationsReport;
    },
    showFrameworksExportButton() {
      return Boolean(this.frameworksCsvExportPath) && this.isFrameworksReport;
    },
    tabIndex() {
      return TABS.indexOf(this.$route.name);
    },
  },
  methods: {
    goTo(name) {
      if (this.$route.name !== name) {
        this.$router.push({ name });
      }
    },
  },
  ROUTE_STANDARDS: ROUTE_STANDARDS_ADHERENCE,
  ROUTE_VIOLATIONS,
  ROUTE_FRAMEWORKS,
  i18n: {
    export: s__('Compliance Center|Export full report as CSV'),
    exportTitle: {
      frameworks: s__(
        'Compliance Center|Export frameworks as CSV. You will be emailed after the export is processed.',
      ),
      violations: s__(
        'Compliance Center|Export merge request violations as CSV. You will be emailed after the export is processed.',
      ),
    },
    frameworksTab: s__('Compliance Center|Frameworks'),
    heading: __('Compliance center'),
    standardsAdherenceTab: s__('Compliance Center|Standards Adherence'),
    subheading: __(
      'Report and manage standards adherence, violations, and compliance frameworks for the group.',
    ),
    violationsTab: s__('Compliance Center|Violations'),
  },
  documentationPath: helpPagePath('user/compliance/compliance_center/index.md'),
};
</script>
<template>
  <div>
    <report-header
      :heading="$options.i18n.heading"
      :subheading="$options.i18n.subheading"
      :documentation-path="$options.documentationPath"
    >
      <template #actions>
        <div align="right">
          <merge-commits-export-button
            v-if="showMergeCommitsExportButton"
            :merge-commits-csv-export-path="mergeCommitsCsvExportPath"
          />
          <gl-button
            v-if="showViolationsExportButton"
            v-gl-tooltip.hover
            :title="$options.i18n.exportTitle.violations"
            :aria-label="$options.i18n.export"
            icon="export"
            data-testid="violations-export"
            class="gl-mt-3"
            :href="violationsCsvExportPath"
          >
            {{ $options.i18n.export }}
          </gl-button>
          <gl-button
            v-if="showFrameworksExportButton"
            v-gl-tooltip.hover
            :title="$options.i18n.exportTitle.frameworks"
            :aria-label="$options.i18n.export"
            icon="export"
            data-testid="framework-export"
            :href="frameworksCsvExportPath"
          >
            {{ $options.i18n.export }}
          </gl-button>
        </div>
      </template>
    </report-header>

    <gl-tabs :value="tabIndex" content-class="gl-p-0" lazy>
      <gl-tab
        v-if="adherenceReportUiEnabled"
        :title="$options.i18n.standardsAdherenceTab"
        data-testid="standards-adherence-tab"
        @click="goTo($options.ROUTE_STANDARDS)"
      />
      <gl-tab
        :title="$options.i18n.violationsTab"
        data-testid="violations-tab"
        @click="goTo($options.ROUTE_VIOLATIONS)"
      />
      <gl-tab
        :title="$options.i18n.frameworksTab"
        :title-link-attributes="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
          'data-qa-selector': 'frameworks_tab',
        } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
        data-testid="frameworks-tab"
        @click="goTo($options.ROUTE_FRAMEWORKS)"
      />
    </gl-tabs>
    <router-view />
  </div>
</template>
