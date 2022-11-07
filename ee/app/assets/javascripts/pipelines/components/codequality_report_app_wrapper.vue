<script>
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';
import CodequalityReportAppGraphql from 'ee/codequality_report/codequality_report_graphql.vue';

export default {
  components: {
    CodequalityReportApp,
    CodequalityReportAppGraphql,
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'codequalityBlobPath',
    'codequalityReportDownloadPath',
    'codequalityProjectPath',
    'pipelineIid',
  ],
  computed: {
    isGraphqlCodeQuality() {
      return this.glFeatures.graphqlCodeQualityFullReport;
    },
  },
};
</script>
<template>
  <codequality-report-app-graphql v-if="isGraphqlCodeQuality" v-on="$listeners" />
  <codequality-report-app
    v-else
    :endpoint="codequalityReportDownloadPath"
    :blob-path="codequalityBlobPath"
    :project-path="codequalityProjectPath"
    :pipeline-iid="pipelineIid"
    v-on="$listeners"
  />
</template>
