<script>
import { GlAlert, GlCollapse, GlEmptyState, GlFormCheckbox } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import Pagination from '~/vue_shared/components/pagination_links.vue';
import SecurityDashboardTableRow from './security_dashboard_table_row.vue';
import SelectionSummary from './selection_summary_vuex.vue';

export default {
  name: 'SecurityDashboardTable',
  components: {
    GlAlert,
    GlCollapse,
    GlEmptyState,
    GlFormCheckbox,
    Pagination,
    SecurityDashboardTableRow,
    SelectionSummary,
  },
  computed: {
    ...mapState('vulnerabilities', [
      'errorLoadingVulnerabilities',
      'errorLoadingVulnerabilitiesCount',
      'isLoadingVulnerabilities',
      'isDismissingVulnerabilities',
      'pageInfo',
      'vulnerabilities',
    ]),
    ...mapState('filters', ['filters']),
    ...mapGetters('vulnerabilities', [
      'dashboardListError',
      'hasSelectedAllVulnerabilities',
      'isSelectingVulnerabilities',
    ]),
    showEmptyState() {
      return (
        this.vulnerabilities &&
        !this.vulnerabilities.length &&
        !this.errorLoadingVulnerabilities &&
        !this.errorLoadingVulnerabilitiesCount
      );
    },
    showPagination() {
      return this.pageInfo && this.pageInfo.total;
    },
  },
  methods: {
    ...mapActions('vulnerabilities', [
      'deselectAllVulnerabilities',
      'fetchVulnerabilities',
      'selectAllVulnerabilities',
    ]),
    fetchPage(page) {
      this.fetchVulnerabilities({ ...this.filters, page });
    },
    handleSelectAll() {
      return this.hasSelectedAllVulnerabilities
        ? this.deselectAllVulnerabilities()
        : this.selectAllVulnerabilities();
    },
  },
};
</script>

<template>
  <div class="ci-table js-security-dashboard-table" data-qa-selector="security_report_content">
    <gl-collapse :visible="isSelectingVulnerabilities" data-testid="selection-summary-collapse">
      <selection-summary />
    </gl-collapse>
    <div class="gl-responsive-table-row table-row-header gl-bg-gray-50 text-2 px-2" role="row">
      <div class="table-section section-5">
        <gl-form-checkbox
          :checked="hasSelectedAllVulnerabilities"
          class="my-0 ml-1 mr-3"
          @change="handleSelectAll"
        />
      </div>
      <div class="table-section section-15" role="rowheader">
        {{ s__('Reports|Severity') }}
      </div>
      <div class="table-section flex-grow-1" role="rowheader">
        {{ s__('Reports|Vulnerability') }}
      </div>
      <div class="table-section section-15" role="rowheader">
        {{ s__('Reports|Identifier') }}
      </div>
      <div class="table-section section-15" role="rowheader">
        {{ s__('Reports|Tool') }}
      </div>
      <div class="table-section section-20" role="rowheader"></div>
    </div>

    <gl-alert v-if="dashboardListError" variant="danger" :dismissible="false" class="gl-mt-3">
      {{
        s__(
          'SecurityReports|Error fetching the vulnerability list. Please check your network connection and try again.',
        )
      }}
    </gl-alert>

    <template v-if="isLoadingVulnerabilities || isDismissingVulnerabilities">
      <security-dashboard-table-row v-for="n in 10" :key="n" :is-loading="true" />
    </template>

    <template v-else>
      <security-dashboard-table-row
        v-for="vulnerability in vulnerabilities"
        :key="vulnerability.id"
        :vulnerability="vulnerability"
      />

      <slot v-if="showEmptyState" name="empty-state">
        <gl-empty-state
          :title="__(`We've found no vulnerabilities`)"
          :description="
            __(
              `While it's rare to have no vulnerabilities, it can happen. In any event, we ask that you please double check your settings to make sure you've set up your dashboard correctly.`,
            )
          "
        />
      </slot>

      <pagination
        v-if="showPagination"
        :change="fetchPage"
        :page-info="pageInfo"
        class="justify-content-center gl-mt-3"
      />
    </template>
  </div>
</template>
