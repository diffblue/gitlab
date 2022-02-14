<script>
import { GlSkeletonLoader, GlCard, GlLink, GlIcon, GlPopover } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import { percent, percentHundred } from '~/lib/utils/unit_format';
import { helpPagePath } from '~/helpers/help_page_helper';
import getProjectQuality from './graphql/queries/get_project_quality.query.graphql';
import { formatStat } from './utils';

export default {
  components: {
    GlSkeletonLoader,
    GlCard,
    GlLink,
    GlIcon,
    GlPopover,
    GlSingleStat,
  },
  inject: {
    projectPath: {
      type: String,
      default: '',
    },
    coverageChartPath: {
      type: String,
      default: '',
    },
    defaultBranch: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      projectQuality: {},
    };
  },
  apollo: {
    projectQuality: {
      query: getProjectQuality,
      variables() {
        return {
          projectPath: this.projectPath,
          defaultBranch: this.defaultBranch,
        };
      },
      update(data) {
        return data.project?.pipelines?.nodes[0];
      },
      error(error) {
        createFlash({
          message: this.$options.i18n.fetchError,
          error,
        });
      },
    },
  },
  computed: {
    testSuccessPercentage() {
      return formatStat(
        this.projectQuality?.testReportSummary.total.success /
          this.projectQuality?.testReportSummary.total.count,
        percent,
      );
    },
    testFailurePercentage() {
      return formatStat(
        this.projectQuality?.testReportSummary.total.failed /
          this.projectQuality?.testReportSummary.total.count,
        percent,
      );
    },
    testSkippedPercentage() {
      return formatStat(
        this.projectQuality?.testReportSummary.total.skipped /
          this.projectQuality?.testReportSummary.total.count,
        percent,
      );
    },
    coveragePercentage() {
      return formatStat(this.projectQuality?.coverage, percentHundred);
    },
    pipelineTestReportPath() {
      return `${this.projectQuality?.pipelinePath}/test_report`;
    },
  },
  i18n: {
    testRuns: {
      title: s__('ProjectQualitySummary|Test runs'),
      popoverBody: s__(
        'ProjectQualitySummary|The percentage of tests that succeed, fail, or are skipped.',
      ),
      learnMoreLink: s__('ProjectQualitySummary|Learn more about test reports'),
      fullReportLink: s__('ProjectQualitySummary|See full report'),
      successLabel: s__('ProjectQualitySummary|Success'),
      failureLabel: s__('ProjectQualitySummary|Failure'),
      skippedLabel: s__('ProjectQualitySummary|Skipped'),
    },
    coverage: {
      title: s__('ProjectQualitySummary|Test coverage'),
      popoverBody: s__(
        'ProjectQualitySummary|Measure of how much of your code is covered by tests.',
      ),
      learnMoreLink: s__('ProjectQualitySummary|Learn more about test coverage'),
      fullReportLink: s__('ProjectQualitySummary|See project Code Coverage Statistics'),
      coverageLabel: s__('ProjectQualitySummary|Coverage'),
    },
    subHeader: s__('ProjectQualitySummary|Latest pipeline results'),
    fetchError: s__(
      'ProjectQualitySummary|An error occurred while trying to fetch project quality statistics',
    ),
  },
  testRunsHelpPath: helpPagePath('ci/unit_test_reports'),
  coverageHelpPath: helpPagePath('ci/pipelines/settings', {
    anchor: 'add-test-coverage-results-to-a-merge-request',
  }),
};
</script>
<template>
  <div>
    <gl-card class="gl-mt-6">
      <template #header>
        <div class="gl-display-flex gl-justify-content-space-between gl-align-items-baseline">
          <h4 class="gl-m-2">{{ $options.i18n.testRuns.title }}</h4>
          <gl-icon
            id="test-runs-question-icon"
            name="question-o"
            class="gl-text-blue-600 gl-cursor-pointer gl-mx-2"
          />
          <gl-popover
            target="test-runs-question-icon"
            :title="$options.i18n.testRuns.title"
            placement="top"
            container="viewport"
            triggers="hover focus"
          >
            <p>{{ $options.i18n.testRuns.popoverBody }}</p>
            <gl-link :href="$options.testRunsHelpPath" class="gl-font-sm" target="_blank">
              {{ $options.i18n.testRuns.learnMoreLink }}
            </gl-link>
          </gl-popover>
          <strong class="gl-text-gray-500 gl-mx-2">{{ $options.i18n.subHeader }}</strong>
          <gl-link
            :href="pipelineTestReportPath"
            class="gl-flex-grow-1 gl-text-right gl-mx-2"
            data-testid="test-runs-link"
          >
            {{ $options.i18n.testRuns.fullReportLink }}
          </gl-link>
        </div>
      </template>
      <template #default>
        <gl-skeleton-loader v-if="$apollo.queries.projectQuality.loading" />
        <div v-else-if="projectQuality.testReportSummary" class="row gl-ml-2">
          <gl-single-stat
            class="col-sm-6 col-md-4"
            data-testid="test-runs-stat"
            :title="$options.i18n.testRuns.successLabel"
            :value="testSuccessPercentage"
            variant="success"
            meta-text="Passed"
            meta-icon="status_success"
          />
          <gl-single-stat
            class="col-sm-6 col-md-4"
            data-testid="test-runs-stat"
            :title="$options.i18n.testRuns.failureLabel"
            :value="testFailurePercentage"
            variant="danger"
            meta-text="Failed"
            meta-icon="status_failed"
          />
          <gl-single-stat
            class="col-sm-6 col-md-4"
            data-testid="test-runs-stat"
            :title="$options.i18n.testRuns.skippedLabel"
            :value="testSkippedPercentage"
            variant="neutral"
            meta-text="Skipped"
            meta-icon="status_skipped"
          />
        </div>
      </template>
    </gl-card>
    <gl-card class="gl-mt-6">
      <template #header>
        <div class="gl-display-flex gl-justify-content-space-between gl-align-items-baseline">
          <h4 class="gl-m-2">{{ $options.i18n.coverage.title }}</h4>
          <gl-icon
            id="coverage-question-icon"
            name="question-o"
            class="gl-text-blue-600 gl-cursor-pointer gl-mx-2"
          />
          <gl-popover
            target="coverage-question-icon"
            :title="$options.i18n.coverage.title"
            placement="top"
            container="viewport"
            triggers="hover focus"
          >
            <p>{{ $options.i18n.coverage.popoverBody }}</p>
            <gl-link :href="$options.coverageHelpPath" class="gl-font-sm" target="_blank">
              {{ $options.i18n.coverage.learnMoreLink }}
            </gl-link>
          </gl-popover>
          <strong class="gl-text-gray-500 gl-mx-2">{{ $options.i18n.subHeader }}</strong>
          <gl-link
            :href="coverageChartPath"
            class="gl-flex-grow-1 gl-text-right gl-mx-2"
            data-testid="coverage-link"
          >
            {{ $options.i18n.coverage.fullReportLink }}
          </gl-link>
        </div>
      </template>
      <template #default>
        <gl-skeleton-loader v-if="$apollo.queries.projectQuality.loading" />
        <gl-single-stat
          v-else
          :title="$options.i18n.coverage.coverageLabel"
          :value="coveragePercentage"
          data-testid="coverage-stat"
        />
      </template>
    </gl-card>
  </div>
</template>
