<script>
import { GlTab, GlTabs } from '@gitlab/ui';

import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

import { ROUTE_FRAMEWORKS, ROUTE_VIOLATIONS, TABS } from '../constants';
import MergeCommitsExportButton from './violations_report/shared/merge_commits_export_button.vue';
import ReportHeader from './shared/report_header.vue';

export default {
  name: 'ComplianceReportsApp',
  components: {
    GlTabs,
    GlTab,
    MergeCommitsExportButton,
    ReportHeader,
  },
  props: {
    mergeCommitsCsvExportPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isViolationsReport() {
      return this.$route.name === ROUTE_VIOLATIONS;
    },
    hasMergeCommitsCsvExportPath() {
      return Boolean(this.mergeCommitsCsvExportPath);
    },
    showViolationsExportButton() {
      return this.hasMergeCommitsCsvExportPath && this.isViolationsReport;
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
  ROUTE_VIOLATIONS,
  ROUTE_FRAMEWORKS,
  i18n: {
    frameworksTab: s__('Compliance Report|Frameworks'),
    heading: __('Compliance report'),
    subheading: __('Compliance violations and compliance frameworks for the group.'),
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

    <gl-tabs :value="tabIndex" content-class="gl-pt-5" lazy>
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
