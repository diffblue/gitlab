<script>
import { GlDaterangePicker, GlFormInput } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import ProjectsDropdownFilter from '~/analytics/shared/components/projects_dropdown_filter.vue';
import { pikadayToString, parsePikadayDate } from '~/lib/utils/datetime_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { CURRENT_DATE } from 'ee/audit_events/constants';
import getGroupProjects from '../../../graphql/violation_group_projects.query.graphql';
import { convertProjectIdsToGraphQl } from '../../../utils';

export default {
  components: {
    GlDaterangePicker,
    GlFormInput,
    ProjectsDropdownFilter,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    defaultQuery: {
      type: Object,
      required: true,
    },
    showProjectFilter: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      filterQuery: { ...this.defaultQuery },
      defaultProjects: [],
      loadingDefaultProjects: false,
    };
  },
  computed: {
    defaultStartDate() {
      return parsePikadayDate(this.defaultQuery.mergedAfter);
    },
    defaultEndDate() {
      return parsePikadayDate(this.defaultQuery.mergedBefore);
    },
  },
  async created() {
    if (this.showProjectFilter && this.defaultQuery.projectIds?.length > 0) {
      const projectIds = convertProjectIdsToGraphQl(this.defaultQuery.projectIds);
      this.defaultProjects = await this.fetchProjects(projectIds);
    }
  },
  methods: {
    fetchProjects(projectIds) {
      const { groupPath } = this;
      this.loadingDefaultProjects = true;

      return this.$apollo
        .query({
          query: getGroupProjects,
          variables: { groupPath, projectIds },
        })
        .then((response) => response.data?.group?.projects?.nodes)
        .catch((error) => Sentry.captureException(error))
        .finally(() => {
          this.loadingDefaultProjects = false;
        });
    },
    projectsChanged(projects) {
      const projectIds = projects.map(({ id }) => getIdFromGraphQLId(id));
      this.updateFilter({ projectIds });
    },
    dateRangeChanged({ startDate = this.defaultStartDate, endDate = this.defaultEndDate }) {
      this.updateFilter({
        mergedAfter: pikadayToString(startDate),
        mergedBefore: pikadayToString(endDate),
      });
    },
    updateFilter(query) {
      this.filterQuery = { ...this.filterQuery, ...query };
      this.$emit('filters-changed', this.filterQuery);
    },
  },
  i18n: {
    projectFilterLabel: __('Projects'),
    branchFilterLabel: s__('ComplianceReport|Search target branch'),
    branchFilterPlaceholder: s__('ComplianceReport|Full target branch name'),
  },
  DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
  defaultMaxDate: CURRENT_DATE,
  projectsFilterParams: {
    first: 50,
    includeSubgroups: true,
  },
  dateRangePickerClass: 'gl-display-flex gl-flex-direction-column gl-w-full gl-md-w-auto',
};
</script>

<template>
  <div
    class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row row-content-block gl-pb-0 gl-mb-5 gl-gap-5"
  >
    <div class="gl-display-flex gl-flex-direction-column gl-mb-5 gl-md-pr-5 gl-sm-gap-3">
      <label data-testid="dropdown-label" class="gl-line-height-normal">{{
        $options.i18n.projectFilterLabel
      }}</label>
      <projects-dropdown-filter
        v-if="showProjectFilter"
        data-testid="violations-project-dropdown"
        class="gl-mb-2 gl-lg-mb-0 compliance-filter-dropdown-input"
        :group-namespace="groupPath"
        :query-params="$options.projectsFilterParams"
        :multi-select="true"
        :default-projects="defaultProjects"
        :loading-default-projects="loadingDefaultProjects"
        @selected="projectsChanged"
      />
    </div>

    <gl-daterange-picker
      class="gl-display-flex gl-mb-5"
      data-testid="violations-date-range-picker"
      :default-start-date="defaultStartDate"
      :default-end-date="defaultEndDate"
      :default-max-date="$options.defaultMaxDate"
      :start-picker-class="`${$options.dateRangePickerClass} gl-mr-5`"
      :end-picker-class="$options.dateRangePickerClass"
      date-range-indicator-class="gl-m-0!"
      :same-day-selection="false"
      @input="dateRangeChanged"
    />

    <div class="gl-display-flex gl-flex-direction-column gl-mb-5 gl-md-pr-5 gl-sm-gap-3">
      <label class="gl-line-height-normal">{{ $options.i18n.branchFilterLabel }}</label>
      <gl-form-input
        :value="filterQuery.targetBranch"
        data-testid="violations-target-branch-input"
        class="gl-mb-2 gl-lg-mb-0"
        :placeholder="$options.i18n.branchFilterPlaceholder"
        :debounce="$options.DEFAULT_DEBOUNCE_AND_THROTTLE_MS"
        @input="updateFilter({ targetBranch: $event })"
      />
    </div>
  </div>
</template>
