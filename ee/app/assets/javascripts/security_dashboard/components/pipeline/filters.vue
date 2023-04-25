<script>
import { GlToggle } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { DISMISSAL_STATES } from 'ee/security_dashboard/store/modules/filters/constants';
import { s__ } from '~/locale';
import SeverityFilter from '../shared/filters/severity_filter.vue';
import ToolFilter from '../shared/filters/tool_filter.vue';

export default {
  i18n: {
    toggleLabel: s__('SecurityReports|Hide dismissed'),
  },
  components: { SeverityFilter, ToolFilter, GlToggle },
  computed: {
    ...mapState('filters', ['filters']),
    hideDismissed: {
      set(isHidden) {
        this.setHideDismissed(isHidden);
      },
      get() {
        return this.filters.scope === DISMISSAL_STATES.DISMISSED;
      },
    },
  },
  methods: {
    ...mapActions('filters', ['setFilter', 'setHideDismissed']),
  },
};
</script>

<template>
  <div class="dashboard-filters border-bottom bg-gray-light">
    <div class="row mx-0 p-2">
      <severity-filter
        class="col-sm-6 col-md-4 col-lg-2 p-2 js-filter"
        data-testid="severity"
        @filter-changed="setFilter"
      />
      <tool-filter
        class="col-sm-6 col-md-4 col-lg-2 p-2 js-filter"
        data-testid="reportType"
        @filter-changed="setFilter"
      />
      <div class="gl-display-flex ml-lg-auto p-2">
        <slot name="buttons"></slot>
        <div class="pl-md-6 gl-pt-1">
          <gl-toggle
            v-model="hideDismissed"
            data-qa-selector="findings_hide_dismissed_toggle"
            :label="$options.i18n.toggleLabel"
          />
        </div>
      </div>
    </div>
  </div>
</template>
