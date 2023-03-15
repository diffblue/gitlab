<script>
import { GlSkeletonLoader, GlCard, GlLink, GlIcon, GlPopover } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { createAlert } from '~/alert';
import { percent, percentHundred } from '~/lib/utils/unit_format';
import { helpPagePath } from '~/helpers/help_page_helper';
import TestRunsEmptyState from './components/test_runs_empty_state.vue';
import FeedbackBanner from './components/feedback_banner.vue';
import getProjectQuality from './graphql/queries/get_project_quality.query.graphql';
import { formatStat } from './utils';
import { i18n } from './constants';

export default {
  components: {
    GlSkeletonLoader,
    GlCard,
    GlLink,
    GlIcon,
    GlPopover,
    GlSingleStat,
    FeedbackBanner,
    TestRunsEmptyState,
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
        createAlert({
          message: this.$options.i18n.fetchError,
          error,
        });
      },
    },
  },
  computed: {
    hasTestRunsData() {
      return Boolean(this.projectQuality?.testReportSummary?.total.count);
    },
    hasCodeQualityData() {
      return Boolean(this.projectQuality?.codeQualityReportSummary?.count);
    },
    isShowCodeQualityCard() {
      return Boolean(this.$apollo.queries.projectQuality.loading || this.hasCodeQualityData);
    },
    testSuccessPercentage() {
      return formatStat(
        this.projectQuality.testReportSummary.total.success /
          this.projectQuality.testReportSummary.total.count,
        percent,
      );
    },
    testFailurePercentage() {
      return formatStat(
        this.projectQuality.testReportSummary.total.failed /
          this.projectQuality.testReportSummary.total.count,
        percent,
      );
    },
    testSkippedPercentage() {
      return formatStat(
        this.projectQuality.testReportSummary.total.skipped /
          this.projectQuality.testReportSummary.total.count,
        percent,
      );
    },
    coveragePercentage() {
      return formatStat(this.projectQuality?.coverage, percentHundred);
    },
    pipelineTestReportPath() {
      return `${this.projectQuality?.pipelinePath}/test_report`;
    },
    pipelineCodeQualityReportPath() {
      return `${this.projectQuality?.pipelinePath}/codequality_report`;
    },
  },
  i18n,
  testRunsHelpPath: helpPagePath('ci/unit_test_reports'),
  codeQualityHelpPath: helpPagePath('ci/testing/code_quality'),
  coverageHelpPath: helpPagePath('ci/pipelines/settings', {
    anchor: 'add-test-coverage-results-to-a-merge-request',
  }),
};
</script>
<template>
  <div>
    <feedback-banner />
    <gl-card v-if="$apollo.queries.projectQuality.loading || hasTestRunsData" class="gl-mt-6">
      <template #header>
        <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
          <h5 class="gl-font-lg gl-m-2">{{ $options.i18n.testRuns.title }}</h5>
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
        <div v-else class="row gl-ml-2">
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
    <template v-else>
      <test-runs-empty-state class="gl-mt-6" />
      <hr />
    </template>

    <gl-card v-if="isShowCodeQualityCard" class="gl-mt-6">
      <template #header>
        <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
          <h5 class="gl-font-lg gl-m-2">{{ $options.i18n.codeQuality.title }}</h5>
          <gl-icon
            id="code-quality-icon"
            name="question-o"
            class="gl-text-blue-600 gl-cursor-pointer gl-mx-2"
          />
          <gl-popover
            target="code-quality-icon"
            :title="$options.i18n.codeQuality.title"
            placement="top"
            container="viewport"
            triggers="hover focus"
          >
            <p>{{ $options.i18n.codeQuality.popoverBody }}</p>
            <gl-link :href="$options.codeQualityHelpPath" class="gl-font-sm" target="_blank">
              {{ $options.i18n.codeQuality.learnMoreLink }}
            </gl-link>
          </gl-popover>
          <strong class="gl-text-gray-500 gl-mx-2">{{ $options.i18n.subHeader }}</strong>
          <gl-link
            :href="pipelineCodeQualityReportPath"
            class="gl-flex-grow-1 gl-text-right gl-mx-2"
            data-testid="code-quality-link"
          >
            {{ $options.i18n.codeQuality.fullReportLink }}
          </gl-link>
        </div>
      </template>
      <template #default>
        <gl-skeleton-loader v-if="$apollo.queries.projectQuality.loading" />
        <div v-else class="row gl-ml-2">
          <gl-single-stat
            class="col-sm-6 col-md-4"
            data-testid="code-quality-stat"
            :title="$options.i18n.codeQuality.foundLabel"
            :value="projectQuality.codeQualityReportSummary.count"
          />
          <gl-single-stat
            class="col-sm-6 col-md-4"
            title-icon-class="gl-text-red-800"
            data-testid="code-quality-stat"
            title-icon="severity-critical"
            :title="$options.i18n.codeQuality.blockerLabel"
            :value="projectQuality.codeQualityReportSummary.blocker"
            :unit="$options.i18n.codeQuality.unit"
          />
          <gl-single-stat
            class="col-sm-6 col-md-4"
            title-icon-class="gl-text-red-600"
            data-testid="code-quality-stat"
            title-icon="severity-high"
            :title="$options.i18n.codeQuality.criticalLabel"
            :value="projectQuality.codeQualityReportSummary.critical"
            :unit="$options.i18n.codeQuality.unit"
          />
        </div>
      </template>
    </gl-card>

    <gl-card class="gl-mt-6">
      <template #header>
        <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
          <h5 class="gl-font-lg gl-m-2">{{ $options.i18n.coverage.title }}</h5>
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
