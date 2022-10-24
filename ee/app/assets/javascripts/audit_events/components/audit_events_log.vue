<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { createToken } from '../token_utils';
import AuditEventsExportButton from './audit_events_export_button.vue';
import AuditEventsFilter from './audit_events_filter.vue';
import AuditEventsTable from './audit_events_table.vue';
import DateRangeField from './date_range_field.vue';
import SortingField from './sorting_field.vue';

export default {
  components: {
    AuditEventsFilter,
    DateRangeField,
    SortingField,
    AuditEventsTable,
    AuditEventsExportButton,
  },
  inject: [
    'events',
    'isLastPage',
    'filterTokenOptions',
    'exportUrl',
    'filterViewOnly',
    'filterTokenValues',
  ],
  computed: {
    ...mapState(['filterValue', 'startDate', 'endDate', 'sortBy']),
    ...mapGetters(['buildExportHref']),
    exportHref() {
      return this.buildExportHref(this.exportUrl);
    },
    hasExportUrl() {
      return this.exportUrl.length;
    },
  },
  created() {
    if (this.filterTokenValues.length > 0) {
      this.setFilterValue(this.filterTokenValues.map(createToken));
    }
  },
  methods: {
    ...mapActions(['setDateRange', 'setFilterValue', 'setSortBy', 'searchForAuditEvents']),
  },
};
</script>

<template>
  <div>
    <header v-if="hasExportUrl">
      <div class="gl-my-5 gl-display-flex gl-flex-direction-row gl-justify-content-end">
        <audit-events-export-button :export-href="exportHref" />
      </div>
    </header>
    <div class="row-content-block second-block gl-pb-0">
      <div class="gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row!">
        <audit-events-filter
          :filter-token-options="filterTokenOptions"
          :value="filterValue"
          :view-only="filterViewOnly"
          class="gl-mr-5 gl-mb-5"
          @selected="setFilterValue"
          @submit="searchForAuditEvents"
        />
        <sorting-field :sort-by="sortBy" @selected="setSortBy" />
      </div>
      <date-range-field :start-date="startDate" :end-date="endDate" @selected="setDateRange" />
    </div>
    <audit-events-table :events="events" :is-last-page="isLastPage" />
  </div>
</template>
