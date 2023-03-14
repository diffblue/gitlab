<script>
import {
  GlAlert,
  GlButton,
  GlDropdown,
  GlDropdownSectionHeader,
  GlDropdownItem,
  GlModal,
  GlModalDirective,
} from '@gitlab/ui';
import { pikadayToString } from '~/lib/utils/datetime_utility';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import { downloadi18n as i18n, lastXDays } from '../constants';
import SelectProjectsDropdown from './select_projects_dropdown.vue';

export default {
  name: 'DownloadTestCoverage',
  components: {
    GlAlert,
    GlButton,
    GlDropdown,
    GlDropdownSectionHeader,
    GlDropdownItem,
    GlModal,
    SelectProjectsDropdown,
  },
  directives: {
    GlModalDirective,
  },
  inject: {
    groupAnalyticsCoverageReportsPath: {
      default: '',
    },
  },
  data() {
    return {
      hasError: false,
      allProjectsSelected: false,
      selectedDateRange: this.$options.dateRangeOptions[2],
      selectedProjectIds: [],
    };
  },
  computed: {
    cancelModalButton() {
      return {
        text: __('Cancel'),
      };
    },
    csvReportPath() {
      const today = new Date();
      const endDate = pikadayToString(today);
      today.setDate(today.getDate() - this.selectedDateRange.value);
      const startDate = pikadayToString(today);

      const queryParams = {
        start_date: startDate,
        end_date: endDate,
      };

      // not including a project_ids param is the same as selecting all the projects
      if (!this.allProjectsSelected && this.selectedProjectIds.length) {
        queryParams.project_ids = this.selectedProjectIds;
      }

      return mergeUrlParams(queryParams, this.groupAnalyticsCoverageReportsPath, {
        spreadArrays: true,
      });
    },
    downloadCSVModalButton() {
      return {
        text: this.$options.i18n.downloadCSVModalButton,
        attributes: {
          variant: 'confirm',
          href: this.csvReportPath,
          rel: 'nofollow',
          download: '',
          disabled: this.isDownloadButtonDisabled,
          'data-testid': 'group-code-coverage-download-button',
        },
      };
    },
    isDownloadButtonDisabled() {
      return !this.allProjectsSelected && !this.selectedProjectIds.length;
    },
  },
  methods: {
    clickDateRange(dateRange) {
      this.selectedDateRange = dateRange;
    },
    clickSelectAllProjects() {
      this.$refs.projectsDropdown.clickSelectAllProjects();
    },
    dismissError() {
      this.hasError = false;
    },
    projectsQueryError() {
      this.hasError = true;
    },
    selectAllProjects() {
      this.allProjectsSelected = true;
      this.selectedProjectIds = [];
    },
    selectProject({ parsedId }) {
      this.allProjectsSelected = false;
      const index = this.selectedProjectIds.indexOf(parsedId);
      if (index < 0) {
        this.selectedProjectIds.push(parsedId);
        return;
      }
      this.selectedProjectIds.splice(index, 1);
    },
  },
  i18n,
  dateRangeOptions: [
    { value: 7, text: __('Last week') },
    { value: 14, text: sprintf(__('Last 2 weeks')) },
    { value: 30, text: sprintf(lastXDays, { days: 30 }) },
    { value: 60, text: sprintf(lastXDays, { days: 60 }) },
    { value: 90, text: sprintf(lastXDays, { days: 90 }) },
  ],
};
</script>

<template>
  <div class="gl-xs-w-full gl-sm-ml-3">
    <gl-button
      v-gl-modal-directive="'download-csv-modal'"
      category="primary"
      variant="confirm"
      class="gl-xs-w-full"
      data-testid="group-code-coverage-modal-button"
      :aria-label="$options.i18n.downloadCSVButton"
      >{{ $options.i18n.downloadCSVButton }}</gl-button
    >

    <gl-modal
      modal-id="download-csv-modal"
      :title="$options.i18n.downloadTestCoverageHeader"
      no-fade
      :action-primary="downloadCSVModalButton"
      :action-cancel="cancelModalButton"
    >
      <gl-alert
        v-if="hasError"
        variant="danger"
        data-testid="group-code-coverage-projects-error"
        @dismiss="dismissError"
        >{{ $options.i18n.queryErrorMessage }}</gl-alert
      >
      <div>{{ $options.i18n.downloadCSVModalDescription }}</div>
      <div class="gl-my-4">
        <label class="gl-display-block col-form-label-sm col-form-label">
          {{ $options.i18n.projectDropdownHeader }}
        </label>
        <select-projects-dropdown
          ref="projectsDropdown"
          class="gl-w-half"
          @projects-query-error="projectsQueryError"
          @select-all-projects="selectAllProjects"
          @select-project="selectProject"
        />

        <gl-button
          class="gl-ml-2"
          variant="link"
          data-testid="group-code-coverage-select-all-projects-button"
          @click="clickSelectAllProjects()"
          >{{ $options.i18n.projectSelectAll }}</gl-button
        >
      </div>

      <div class="gl-my-4">
        <label class="gl-display-block col-form-label-sm col-form-label">
          {{ $options.i18n.dateRangeHeader }}
        </label>
        <gl-dropdown :text="selectedDateRange.text" class="gl-w-half">
          <gl-dropdown-section-header>
            {{ $options.i18n.dateRangeHeader }}
          </gl-dropdown-section-header>
          <gl-dropdown-item
            v-for="dateRange in $options.dateRangeOptions"
            :key="dateRange.value"
            :data-testid="`group-code-coverage-download-select-date-${dateRange.value}`"
            @click="clickDateRange(dateRange)"
            >{{ dateRange.text }}</gl-dropdown-item
          >
        </gl-dropdown>
      </div>
    </gl-modal>
  </div>
</template>
