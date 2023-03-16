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
      s__('Analytics|Visualization Type')
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
          >{{ s__('Analytics|Line Chart') }}</gl-button
        >
        <gl-button
          :selected="selectedVisualizationType === 'ColumnChart'"
          class="gl-mb-2"
          icon="chart"
          block
          data-testid="columnchart-button"
          @click="selectVisualizationType('ColumnChart')"
          >{{ s__('Analytics|Column Chart') }}</gl-button
        >
        <gl-button
          :selected="selectedVisualizationType === 'DataTable'"
          class="gl-mb-2"
          icon="table"
          block
          data-testid="datatable-button"
          @click="selectVisualizationType('DataTable')"
          >{{ s__('Analytics|Data Table') }}</gl-button
        >
        <gl-button
          :selected="selectedVisualizationType === 'SingleStat'"
          class="gl-mb-2"
          icon="table"
          block
          data-testid="singlestat-button"
          @click="selectVisualizationType('SingleStat')"
          >{{ s__('Analytics|Single Statistic') }}</gl-button
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
          >{{ s__('Analytics|Line Chart') }}</gl-dropdown-item
        >
        <gl-dropdown-item
          icon-name="chart"
          data-testid="columnchart-dd-item"
          @click="selectVisualizationType('ColumnChart')"
          >{{ s__('Analytics|Column Chart') }}</gl-dropdown-item
        >
        <gl-dropdown-item
          icon-name="table"
          data-testid="datatable-dd-item"
          @click="selectVisualizationType('DataTable')"
          >{{ s__('Analytics|Data Table') }}</gl-dropdown-item
        >
        <gl-dropdown-item
          icon-name="table"
          data-testid="singlestat-dd-item"
          @click="selectVisualizationType('SingleStat')"
          >{{ s__('Analytics|Single Statistic') }}</gl-dropdown-item
        >
      </gl-dropdown>
    </div>
  </div>
</template>
