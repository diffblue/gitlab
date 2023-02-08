<script>
import { GlDropdown, GlDropdownItem, GlButton } from '@gitlab/ui';

export default {
  name: 'AnalyticsVisualizationInspector',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlButton,
  },
  props: {
    selectedVisualizationType: {
      type: String,
      required: true,
    },
  },
  methods: {
    selectVisualizationType(visualizationType) {
      this.$emit('selectVisualizationType', visualizationType);
    },
  },
};
</script>

<template>
  <div class="gl-pt-4">
    <label id="label" class="gl-font-weight-bold gl-mb-2">{{
      s__('ProductAnalytics|Visualization Type')
    }}</label>
    <div v-if="!selectedVisualizationType">
      <div>
        <gl-button
          :selected="selectedVisualizationType === 'LineChart'"
          class="gl-mb-2"
          icon="chart"
          block
          data-testid="linechart-button"
          @click="selectVisualizationType('LineChart')"
          >{{ s__('ProductAnalytics|Line Chart') }}</gl-button
        >
        <gl-button
          :selected="selectedVisualizationType === 'DataTable'"
          class="gl-mb-2"
          icon="table"
          block
          data-testid="datatable-button"
          @click="selectVisualizationType('DataTable')"
          >{{ s__('ProductAnalytics|Data Table') }}</gl-button
        >
        <gl-button
          :selected="selectedVisualizationType === 'SingleStat'"
          class="gl-mb-2"
          icon="table"
          block
          data-testid="singlestat-button"
          @click="selectVisualizationType('SingleStat')"
          >{{ s__('ProductAnalytics|Single Statistic') }}</gl-button
        >
      </div>
    </div>
    <div v-else class="gl-mt-4">
      <gl-dropdown
        :text="selectedVisualizationType"
        icon="chart"
        multiple
        block
        label="Chart"
        data-testid="chart-dd"
      >
        <gl-dropdown-item
          icon-name="chart"
          data-testid="linechart-dd-item"
          @click="selectVisualizationType('LineChart')"
          >{{ s__('ProductAnalytics|Line Chart') }}</gl-dropdown-item
        >
        <gl-dropdown-item
          icon-name="table"
          data-testid="datatable-dd-item"
          @click="selectVisualizationType('DataTable')"
          >{{ s__('ProductAnalytics|Data Table') }}</gl-dropdown-item
        >
        <gl-dropdown-item
          icon-name="table"
          data-testid="singlestat-dd-item"
          @click="selectVisualizationType('SingleStat')"
          >{{ s__('ProductAnalytics|Single Statistic') }}</gl-dropdown-item
        >
      </gl-dropdown>
    </div>
  </div>
</template>
