<script>
import { GlAlert, GlButton, GlLoadingIcon } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { pushEECproductAddToCartEvent } from '~/google_tag_manager';
import getCiMinutesUsageProfile from '../graphql/queries/ci_minutes.query.graphql';
import getCiMinutesUsageNamespace from '../graphql/queries/ci_minutes_namespace.query.graphql';
import {
  ERROR_MESSAGE,
  LABEL_BUY_ADDITIONAL_MINUTES,
  TITLE_USAGE_SINCE,
  TOTAL_USED_UNLIMITED,
  MINUTES_USED,
  ADDITIONAL_MINUTES,
  PERCENTAGE_USED,
  ADDITIONAL_MINUTES_HELP_LINK,
  CI_MINUTES_HELP_LINK,
  CI_MINUTES_HELP_LINK_LABEL,
} from '../constants';
import ProjectList from './project_list.vue';
import UsageOverview from './usage_overview.vue';
import MinutesUsageCharts from './minutes_usage_charts.vue';

export default {
  name: 'PipelineUsageApp',
  components: { GlAlert, GlButton, GlLoadingIcon, ProjectList, UsageOverview, MinutesUsageCharts },
  inject: [
    'pageSize',
    'namespacePath',
    'namespaceId',
    'namespaceActualPlanName',
    'userNamespace',
    'ciMinutesAnyProjectEnabled',
    'ciMinutesDisplayMinutesAvailableData',
    'ciMinutesLastResetDate',
    'ciMinutesMonthlyMinutesLimit',
    'ciMinutesMonthlyMinutesUsed',
    'ciMinutesMonthlyMinutesUsedPercentage',
    'ciMinutesPurchasedMinutesLimit',
    'ciMinutesPurchasedMinutesUsed',
    'ciMinutesPurchasedMinutesUsedPercentage',
    'buyAdditionalMinutesPath',
    'buyAdditionalMinutesTarget',
  ],
  data() {
    return {
      error: '',
      namespace: null,
      ciMinutesUsage: [],
    };
  },
  apollo: {
    ciMinutesUsage: {
      query() {
        return this.userNamespace ? getCiMinutesUsageProfile : getCiMinutesUsageNamespace;
      },
      variables() {
        return {
          namespaceId: convertToGraphQLId(TYPENAME_GROUP, this.namespaceId),
          first: this.pageSize,
        };
      },
      update(res) {
        return res?.ciMinutesUsage?.nodes;
      },
      error() {
        this.error = ERROR_MESSAGE;
      },
    },
  },
  computed: {
    currentMonthProjectData() {
      return (
        this.ciMinutesUsage.find((usage) => usage.monthIso8601 === this.ciMinutesLastResetDate) ||
        {}
      );
    },
    projects() {
      return this.currentMonthProjectData?.projects?.nodes ?? [];
    },
    projectsPageInfo() {
      return this.currentMonthProjectData?.projects?.pageInfo ?? {};
    },
    shouldShowBuyAdditionalMinutes() {
      return this.buyAdditionalMinutesPath && this.buyAdditionalMinutesTarget;
    },
    isLoading() {
      return this.$apollo.queries.ciMinutesUsage.loading;
    },
    monthlyUsageTitle() {
      return sprintf(TITLE_USAGE_SINCE, {
        usageSince: formatDate(this.ciMinutesLastResetDate, 'mmm dd, yyyy', true),
      });
    },
    monthlyMinutesUsed() {
      return sprintf(MINUTES_USED, {
        minutesUsed: `${this.ciMinutesMonthlyMinutesUsed} / ${this.ciMinutesMonthlyMinutesLimit}`,
      });
    },
    purchasedMinutesUsed() {
      return sprintf(MINUTES_USED, {
        minutesUsed: `${this.ciMinutesPurchasedMinutesUsed} / ${this.ciMinutesPurchasedMinutesLimit}`,
      });
    },
    shouldShowAdditionalMinutes() {
      return (
        this.ciMinutesDisplayMinutesAvailableData && Number(this.ciMinutesPurchasedMinutesLimit) > 0
      );
    },
  },
  methods: {
    clearError() {
      this.error = '';
    },
    fetchMoreProjects(variables) {
      this.$apollo.queries.ciMinutesUsage.fetchMore({
        variables: {
          namespaceId: convertToGraphQLId(TYPENAME_GROUP, this.namespaceId),
          ...variables,
        },
        updateQuery(previousResult, { fetchMoreResult }) {
          return fetchMoreResult;
        },
      });
    },
    trackBuyAdditionalMinutesClick() {
      pushEECproductAddToCartEvent();
    },
    usagePercentage(percentage) {
      let percentageUsed;
      if (this.ciMinutesDisplayMinutesAvailableData) {
        percentageUsed = percentage;
      } else if (this.ciMinutesAnyProjectEnabled) {
        percentageUsed = 0;
      }

      if (percentageUsed) {
        return sprintf(PERCENTAGE_USED, {
          percentageUsed,
        });
      }

      return TOTAL_USED_UNLIMITED;
    },
  },
  LABEL_BUY_ADDITIONAL_MINUTES,
  ADDITIONAL_MINUTES,
  ADDITIONAL_MINUTES_HELP_LINK,
  CI_MINUTES_HELP_LINK,
  CI_MINUTES_HELP_LINK_LABEL,
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />
    <gl-alert v-else-if="error" variant="danger" @dismiss="clearError">
      {{ error }}
    </gl-alert>
    <section v-else>
      <section>
        <div
          v-if="shouldShowBuyAdditionalMinutes"
          class="gl-display-flex gl-justify-content-end gl-py-3"
        >
          <gl-button
            :href="buyAdditionalMinutesPath"
            :target="buyAdditionalMinutesTarget"
            :aria-label="$options.LABEL_BUY_ADDITIONAL_MINUTES"
            :data-track-label="namespaceActualPlanName"
            data-qa-selector="buy_ci_minutes"
            data-track-action="click_buy_ci_minutes"
            data-track-property="pipeline_quota_page"
            category="primary"
            variant="confirm"
            class="js-buy-additional-minutes"
            @click="trackBuyAdditionalMinutesClick"
          >
            {{ $options.LABEL_BUY_ADDITIONAL_MINUTES }}
          </gl-button>
        </div>
        <usage-overview
          :class="{ 'gl-pt-5': !shouldShowBuyAdditionalMinutes }"
          :minutes-title="monthlyUsageTitle"
          :minutes-used="monthlyMinutesUsed"
          minutes-used-qa-selector="plan_ci_minutes"
          :minutes-used-percentage="usagePercentage(ciMinutesMonthlyMinutesUsedPercentage)"
          :minutes-limit="ciMinutesMonthlyMinutesLimit"
          :help-link-href="$options.CI_MINUTES_HELP_LINK"
          :help-link-label="$options.CI_MINUTES_HELP_LINK_LABEL"
          data-testid="monthly-usage-overview"
        />
        <usage-overview
          v-if="shouldShowAdditionalMinutes"
          class="gl-pt-5"
          :minutes-title="$options.ADDITIONAL_MINUTES"
          :minutes-used="purchasedMinutesUsed"
          minutes-used-qa-selector="additional_ci_minutes"
          :minutes-used-percentage="usagePercentage(ciMinutesPurchasedMinutesUsedPercentage)"
          :minutes-limit="ciMinutesPurchasedMinutesLimit"
          :help-link-href="$options.ADDITIONAL_MINUTES_HELP_LINK"
          :help-link-label="$options.ADDITIONAL_MINUTES"
          data-testid="purchased-usage-overview"
        />
      </section>
      <minutes-usage-charts :ci-minutes-usage="ciMinutesUsage" />
      <section class="gl-py-5">
        <project-list
          :projects="projects"
          :page-info="projectsPageInfo"
          @fetchMore="fetchMoreProjects"
        />
      </section>
    </section>
  </div>
</template>
