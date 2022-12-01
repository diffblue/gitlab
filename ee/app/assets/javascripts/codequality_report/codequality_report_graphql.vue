<script>
import { GlSkeletonLoader, GlInfiniteScroll, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { once } from 'lodash';
import produce from 'immer';
import api from '~/api';
import { componentNames } from 'ee/ci/reports/components/issue_body';
import reportsMixin from 'ee/vue_shared/security_reports/mixins/reports_mixin';
import { n__, s__, sprintf } from '~/locale';
import ReportSection from '~/ci/reports/components/report_section.vue';
import CodequalityIssueBody from '~/ci/reports/codequality_report/components/codequality_issue_body.vue';
import { parseCodeclimateMetrics } from '~/ci/reports/codequality_report/store/utils/codequality_parser';
import getCodeQualityViolations from './graphql/queries/get_code_quality_violations.query.graphql';
import { PAGE_SIZE, VIEW_EVENT_NAME } from './store/constants';

export default {
  components: {
    ReportSection,
    CodequalityIssueBody,
    GlSkeletonLoader,
    GlInfiniteScroll,
    GlLoadingIcon,
    GlSprintf,
  },
  mixins: [reportsMixin],
  componentNames,
  inject: ['projectPath', 'pipelineIid', 'blobPath'],
  apollo: {
    codequalityViolations: {
      query: getCodeQualityViolations,
      variables() {
        return {
          projectPath: this.projectPath,
          iid: this.pipelineIid,
          first: PAGE_SIZE,
        };
      },
      update({
        project: {
          pipeline: { codeQualityReports: { nodes = [], pageInfo = {}, count = 0 } = {} } = {},
        } = {},
      }) {
        return {
          nodes,
          parsedList: parseCodeclimateMetrics(nodes, this.blobPath),
          count,
          pageInfo,
        };
      },
      error() {
        this.errored = true;
      },
      watchLoading(isLoading) {
        if (isLoading) {
          this.trackViewEvent();
        }
      },
    },
  },
  data() {
    return {
      codequalityViolations: {
        nodes: [],
        parsedList: [],
        count: 0,
        pageInfo: {},
      },
      errored: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.codequalityViolations.loading;
    },
    hasCodequalityViolations() {
      return this.codequalityViolations.count > 0;
    },
    trackViewEvent() {
      return once(() => {
        api.trackRedisHllUserEvent(VIEW_EVENT_NAME);
      });
    },
    codequalityText() {
      const text = [];
      const { count } = this.codequalityViolations;

      if (count === 0) {
        return s__('ciReport|No code quality issues found');
      } else if (count > 0) {
        return sprintf(s__('ciReport|Found %{issuesWithCount}'), {
          issuesWithCount: n__('%d code quality issue', '%d code quality issues', count),
        });
      }

      return text.join('');
    },
    codequalityStatus() {
      return this.checkReportStatus(this.isLoading && !this.hasCodequalityViolations, this.errored);
    },
  },
  watch: {
    codequalityViolations() {
      this.$emit('updateBadgeCount', this.codequalityViolations.count);
    },
  },
  i18n: {
    subHeading: s__('ciReport|This report contains all Code Quality issues in the source branch.'),
    loadingText: s__('ciReport|Loading Code Quality report'),
    errorText: s__('ciReport|Failed to load Code Quality report'),
    showingCount: s__('ciReport|Showing %{fetchedItems} of %{totalItems} items'),
  },
  methods: {
    fetchMoreViolations() {
      this.$apollo.queries.codequalityViolations
        .fetchMore({
          variables: {
            first: PAGE_SIZE,
            after: this.codequalityViolations.pageInfo.endCursor,
          },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            return produce(fetchMoreResult, (draftData) => {
              draftData.project.pipeline.codeQualityReports.nodes = [
                ...previousResult.project.pipeline.codeQualityReports.nodes,
                ...draftData.project.pipeline.codeQualityReports.nodes,
              ];
            });
          },
        })
        .catch(() => {
          this.errored = true;
        });
    },
  },
};
</script>

<template>
  <div>
    <report-section
      always-open
      :status="codequalityStatus"
      :loading-text="$options.i18n.loadingText"
      :error-text="$options.i18n.errorText"
      :success-text="codequalityText"
      :unresolved-issues="codequalityViolations.parsedList"
      :resolved-issues="[] /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */"
      :has-issues="hasCodequalityViolations"
      :component="$options.componentNames.CodequalityIssueBody"
      class="codequality-report"
    >
      <template v-if="hasCodequalityViolations" #sub-heading>{{
        $options.i18n.subHeading
      }}</template>
      <template #body>
        <gl-infinite-scroll
          :max-list-height="500"
          :fetched-items="codequalityViolations.parsedList.length"
          :total-items="codequalityViolations.count"
          @bottomReached="fetchMoreViolations"
        >
          <template #items>
            <div class="report-block-container">
              <template v-for="(issue, index) in codequalityViolations.parsedList">
                <codequality-issue-body
                  :key="index"
                  :issue="issue"
                  class="report-block-list-issue"
                />
              </template>
            </div>
          </template>
          <template #default>
            <div class="gl-mt-3">
              <gl-loading-icon v-if="isLoading" />
              <gl-sprintf v-else :message="$options.i18n.showingCount"
                ><template #fetchedItems>{{ codequalityViolations.parsedList.length }}</template
                ><template #totalItems>{{ codequalityViolations.count }}</template></gl-sprintf
              >
            </div>
          </template>
        </gl-infinite-scroll>
      </template>
    </report-section>
    <div v-if="isLoading && !hasCodequalityViolations" class="report-block-container">
      <gl-skeleton-loader :lines="36" />
    </div>
  </div>
</template>
