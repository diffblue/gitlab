<script>
import { reportTypeToSecurityReportTypeEnum } from 'ee/vue_shared/security_reports/constants';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import SecurityReportDownloadDropdown from '~/vue_shared/security_reports/components/security_report_download_dropdown.vue';
import securityReportPipelineDownloadPathsQuery from '~/vue_shared/security_reports/graphql/queries/security_report_pipeline_download_paths.query.graphql';
import { extractSecurityReportArtifactsFromPipeline } from '~/vue_shared/security_reports/utils';

export default {
  components: {
    SecurityReportDownloadDropdown,
  },
  props: {
    reportTypes: {
      type: Array,
      required: true,
      validator: (reportType) => {
        return reportType.every((report) => reportTypeToSecurityReportTypeEnum[report]);
      },
    },
    targetProjectFullPath: {
      type: String,
      required: true,
    },
    pipelineIid: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      reportArtifacts: [],
    };
  },
  apollo: {
    reportArtifacts: {
      query: securityReportPipelineDownloadPathsQuery,
      variables() {
        return {
          projectPath: this.targetProjectFullPath,
          iid: String(this.pipelineIid),
          reportTypes: this.reportTypes.map(
            (reportType) => reportTypeToSecurityReportTypeEnum[reportType],
          ),
        };
      },
      update(data) {
        return extractSecurityReportArtifactsFromPipeline(this.reportTypes, data);
      },
      error(error) {
        this.showError(error);
      },
    },
  },
  computed: {
    isLoadingReportArtifacts() {
      return this.$apollo.queries.reportArtifacts.loading;
    },
  },
  methods: {
    showError(error) {
      createAlert({
        message: this.$options.i18n.apiError,
        captureError: true,
        error,
      });
    },
  },
  i18n: {
    apiError: s__(
      'SecurityReports|Failed to get security report information. Please reload the page or try again later.',
    ),
  },
};
</script>

<template>
  <div>
    <slot name="label"></slot>
    <security-report-download-dropdown
      :text="s__('SecurityReports|Download results')"
      :artifacts="reportArtifacts"
      :loading="isLoadingReportArtifacts"
    />
  </div>
</template>
