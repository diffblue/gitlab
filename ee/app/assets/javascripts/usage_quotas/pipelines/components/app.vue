<script>
import {
  GlAlert,
  GlButton,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownItem,
  GlFormGroup,
} from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { formatDate, getMonthNames } from '~/lib/utils/datetime_utility';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { pushEECproductAddToCartEvent } from '~/google_tag_manager';
import getCiMinutesUsageNamespace from '../graphql/queries/ci_minutes.query.graphql';
import getCiMinutesUsageNamespaceProjects from '../graphql/queries/ci_minutes_projects.query.graphql';
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
import { USAGE_BY_MONTH_HEADER, USAGE_BY_PROJECT_HEADER } from '../../constants';
import { getUsageDataByYearAsArray, formatIso8601Date } from '../utils';
import ProjectList from './project_list.vue';
import UsageOverview from './usage_overview.vue';
import MinutesUsagePerMonth from './minutes_usage_per_month.vue';
import MinutesUsagePerProject from './minutes_usage_per_project.vue';

export default {
  name: 'PipelineUsageApp',
  components: {
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlDropdown,
    GlDropdownItem,
    GlFormGroup,
    ProjectList,
    UsageOverview,
    MinutesUsagePerProject,
    MinutesUsagePerMonth,
  },
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
    const lastResetDate = new Date(this.ciMinutesLastResetDate);
    const year = lastResetDate.getUTCFullYear();
    // NOTE: month indexes in JS start from 0. So `(new Date()).getMonth()` for
    // January would be 0. To keep indexes in data humane, it required a few +1
    // and -1 operations with month indexes in this component. Though the result
    // might be not worth the effort juggling the indexes. We can change this to
    // keep 0-based indexes and do a +1 only before we need to present data in
    // text format.
    const month = lastResetDate.getUTCMonth() + 1;

    return {
      error: '',
      namespace: null,
      ciMinutesUsage: [],
      projectsCiMinutesUsage: [],
      selectedYear: year,
      selectedMonth: month,
    };
  },
  apollo: {
    ciMinutesUsage: {
      query() {
        return getCiMinutesUsageNamespace;
      },
      variables() {
        return {
          namespaceId: this.userNamespace
            ? null
            : convertToGraphQLId(TYPENAME_GROUP, this.namespaceId),
        };
      },
      update(res) {
        return res?.ciMinutesUsage?.nodes;
      },
      error() {
        this.error = ERROR_MESSAGE;
      },
    },
    projectsCiMinutesUsage: {
      query() {
        return getCiMinutesUsageNamespaceProjects;
      },
      variables() {
        return {
          namespaceId: this.userNamespace
            ? null
            : convertToGraphQLId(TYPENAME_GROUP, this.namespaceId),
          first: this.pageSize,
          date: this.selectedDateInIso8601,
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
    selectedDateInIso8601() {
      return formatIso8601Date(this.selectedYear, this.selectedMonth, 1);
    },
    selectedMonthProjectData() {
      const monthData = this.projectsCiMinutesUsage.find((usage) => {
        return usage.monthIso8601 === this.selectedDateInIso8601;
      });

      return monthData || {};
    },
    projects() {
      return this.selectedMonthProjectData?.projects?.nodes ?? [];
    },
    projectsPageInfo() {
      return this.selectedMonthProjectData?.projects?.pageInfo ?? {};
    },
    shouldShowBuyAdditionalMinutes() {
      return this.buyAdditionalMinutesPath && this.buyAdditionalMinutesTarget;
    },
    isLoadingYearUsageData() {
      return this.$apollo.queries.ciMinutesUsage.loading;
    },
    isLoadingMonthProjectUsageData() {
      return this.$apollo.queries.projectsCiMinutesUsage.loading;
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
    usageDataByYear() {
      return getUsageDataByYearAsArray(this.ciMinutesUsage);
    },
    years() {
      return Object.keys(this.usageDataByYear).map(Number).reverse();
    },
    months() {
      return getMonthNames();
    },
    projectsTableInfoMessage() {
      return sprintf(
        s__('UsageQuota|The chart and the table below show usage for %{month} %{year}'),
        {
          month: getMonthNames()[this.selectedMonth - 1],
          year: this.selectedYear,
        },
      );
    },
  },
  methods: {
    clearError() {
      this.error = '';
    },
    fetchMoreProjects(variables) {
      this.$apollo.queries.projectsCiMinutesUsage.fetchMore({
        variables: {
          namespaceId: this.userNamespace
            ? null
            : convertToGraphQLId(TYPENAME_GROUP, this.namespaceId),
          date: this.selectedDateInIso8601,
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
  USAGE_BY_MONTH_HEADER,
  USAGE_BY_PROJECT_HEADER,
};
</script>

<template>
  <div>
    <gl-loading-icon
      v-if="isLoadingYearUsageData"
      class="gl-mt-5"
      size="lg"
      data-testid="pipelines-overview-loading-indicator"
    />

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
    </section>

    <div class="gl-display-flex gl-my-5">
      <gl-form-group :label="s__('UsageQuota|Filter charts by year')">
        <gl-dropdown
          :text="selectedYear.toString()"
          :disabled="isLoadingYearUsageData"
          data-testid="minutes-usage-year-dropdown"
        >
          <gl-dropdown-item
            v-for="year in years"
            :key="year"
            :is-checked="selectedYear === year"
            is-check-item
            data-testid="minutes-usage-year-dropdown-item"
            @click="selectedYear = year"
          >
            {{ year }}
          </gl-dropdown-item>
        </gl-dropdown>
      </gl-form-group>
    </div>

    <section class="gl-my-5">
      <h2 class="gl-font-lg">{{ $options.USAGE_BY_MONTH_HEADER }}</h2>

      <gl-loading-icon
        v-if="isLoadingYearUsageData"
        class="gl-mt-5"
        size="lg"
        data-testid="pipelines-by-month-chart-loading-indicator"
      />

      <minutes-usage-per-month
        v-else
        :selected-year="selectedYear"
        :ci-minutes-usage="ciMinutesUsage"
      />
    </section>

    <section class="gl-my-5">
      <h2 class="gl-font-lg">{{ $options.USAGE_BY_PROJECT_HEADER }}</h2>

      <div class="gl-display-flex gl-my-3">
        <gl-form-group :label="s__('UsageQuota|Filter projects data by month')">
          <gl-dropdown
            :text="months[selectedMonth - 1]"
            :disabled="isLoadingMonthProjectUsageData"
            data-testid="minutes-usage-month-dropdown"
          >
            <gl-dropdown-item
              v-for="(month, index) in months"
              :key="month"
              :is-checked="selectedMonth === index + 1"
              is-check-item
              data-testid="minutes-usage-month-dropdown-item"
              @click="selectedMonth = index + 1"
            >
              {{ month }}
            </gl-dropdown-item>
          </gl-dropdown>
        </gl-form-group>
      </div>

      <gl-loading-icon
        v-if="isLoadingMonthProjectUsageData"
        class="gl-mt-5"
        size="lg"
        data-testid="pipelines-by-project-chart-loading-indicator"
      />

      <template v-else>
        <gl-alert :dismissible="false" class="gl-my-3" data-testid="project-usage-info-alert">
          {{ projectsTableInfoMessage }}
        </gl-alert>

        <minutes-usage-per-project
          :selected-year="selectedYear"
          :selected-month="selectedMonth"
          :projects-ci-minutes-usage="projectsCiMinutesUsage"
        />

        <div class="gl-pt-5">
          <project-list
            :projects="projects"
            :page-info="projectsPageInfo"
            @fetchMore="fetchMoreProjects"
          />
        </div>
      </template>
    </section>
  </div>
</template>
