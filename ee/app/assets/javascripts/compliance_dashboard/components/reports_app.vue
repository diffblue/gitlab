<script>
import { GlTab, GlTabs } from '@gitlab/ui';

import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import { TABS, TAB_VIOLATIONS } from '../constants';
import MergeCommitsExportButton from './violations_report/shared/merge_commits_export_button.vue';
import ViolationsReport from './violations_report/report.vue';
import FrameworksReport from './frameworks_report/report.vue';
import ReportHeader from './shared/report_header.vue';

export default {
  name: 'ComplianceReportsApp',
  components: {
    FrameworksReport,
    GlTabs,
    GlTab,
    MergeCommitsExportButton,
    ReportHeader,
    ViolationsReport,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    mergeCommitsCsvExportPath: {
      type: String,
      required: false,
      default: '',
    },
    groupPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isViolationsReport: true,
    };
  },
  computed: {
    hasMergeCommitsCsvExportPath() {
      return Boolean(this.mergeCommitsCsvExportPath);
    },
    showViolationsExportButton() {
      return this.hasMergeCommitsCsvExportPath && this.isViolationsReport;
    },
    showTabs() {
      return Boolean(this.glFeatures?.complianceFrameworksReport);
    },
  },
  methods: {
    onTabChange(tabIndex) {
      this.isViolationsReport = tabIndex === TABS.indexOf(TAB_VIOLATIONS);
    },
  },
  i18n: {
    frameworksTab: s__('Compliance Report|Frameworks'),
    heading: __('Compliance report'),
    subheading: __(
      'The compliance report shows the merge request violations merged in protected environments.',
    ),
    violationsTab: s__('Compliance Report|Violations'),
  },
  documentationPath: helpPagePath('user/compliance/compliance_report/index.md'),
};
</script>
<template>
  <div>
    <report-header
      :heading="$options.i18n.heading"
      :subheading="$options.i18n.subheading"
      :documentation-path="$options.documentationPath"
    >
      <template v-if="showViolationsExportButton" #actions>
        <merge-commits-export-button
          v-if="hasMergeCommitsCsvExportPath"
          :merge-commits-csv-export-path="mergeCommitsCsvExportPath"
        />
      </template>
    </report-header>

    <gl-tabs
      v-if="showTabs"
      content-class="gl-pt-5"
      :sync-active-tab-with-query-params="true"
      lazy
      @input="onTabChange"
    >
      <gl-tab
        :title="$options.i18n.violationsTab"
        query-param-value="violations"
        data-testid="violations-tab"
      >
        <violations-report
          :merge-commits-csv-export-path="mergeCommitsCsvExportPath"
          :group-path="groupPath"
        />
      </gl-tab>
      <gl-tab
        :title="$options.i18n.frameworksTab"
        query-param-value="frameworks"
        data-testid="frameworks-tab"
      >
        <frameworks-report />
      </gl-tab>
    </gl-tabs>
    <!-- This additional violations-report element will be removed in a subsequent MR once tabs are always shown -->
    <violations-report
      v-else
      :merge-commits-csv-export-path="mergeCommitsCsvExportPath"
      :group-path="groupPath"
    />
  </div>
</template>
