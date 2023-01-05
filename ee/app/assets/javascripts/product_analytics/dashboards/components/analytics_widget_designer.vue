<script>
import { QueryBuilder } from '@cubejs-client/vue';
import { GlButton } from '@gitlab/ui';

import { __ } from '~/locale';

import { createCubeJsApi } from '../data_sources/cube_analytics';
import { WIDGET_DISPLAY_TYPES } from '../constants';

import MeasureSelector from './widget_designer/analytics_cube_query_measure_selector.vue';
import DimensionSelector from './widget_designer/analytics_cube_query_dimension_selector.vue';
import WidgetPreview from './widget_designer/analytics_widget_preview.vue';
import VisualizationInspector from './widget_designer/analytics_visualization_inspector.vue';

export default {
  name: 'AnalyticsWidgetDesigner',
  components: {
    QueryBuilder,
    GlButton,
    MeasureSelector,
    DimensionSelector,
    VisualizationInspector,
    WidgetPreview,
  },
  data() {
    const query = {
      limit: 100,
    };

    return {
      cubejsApi: createCubeJsApi(document.body.dataset.projectId),
      queryState: {
        query,
        measureType: '',
        measureSubType: '',
      },
      widgetOptions: {},
      defaultTitle: '',
      selectedDisplayType: WIDGET_DISPLAY_TYPES.DATA,
      selectedVisualizationType: '',
    };
  },
  computed: {
    resultWidget() {
      const newCubeQuery = this.$refs.builder.$children[0].resultSet.query();

      // Weird behaviour as the API says its malformed if we send it again
      delete newCubeQuery.order;
      delete newCubeQuery.rowLimit;
      delete newCubeQuery.queryType;

      return {
        version: 1,
        title: this.defaultTitle,
        type: this.selectedVisualizationType,
        data: {
          type: 'cube_analytics',
          query: newCubeQuery,
        },
        options: this.widgetOptions,
      };
    },
  },
  mounted() {
    // Needs to be dynamic as it can't be changed on the cube component
    const outerShell = document.getElementById('js-query-builder-wrapper');
    if (outerShell) outerShell.childNodes[0].classList.add('gl-display-flex');

    const wrappers = document.querySelectorAll('.container-fluid.container-limited');

    wrappers.forEach((el) => {
      el.classList.remove('container-limited');
    });
  },
  methods: {
    measureUpdated(measureType, measureSubType) {
      this.queryState.measureType = measureType;
      this.queryState.measureSubType = measureSubType;
    },
    selectDisplayType(newType) {
      this.selectedDisplayType = newType;
    },
    selectVisualizationType(newType) {
      this.selectDisplayType(WIDGET_DISPLAY_TYPES.WIDGET);
      this.selectedVisualizationType = newType;

      if (this.selectedVisualizationType === 'LineChart') {
        this.widgetOptions = {
          xAxis: {
            name: __('Time'),
            type: 'time',
          },
          yAxis: {
            name: __('Counts'),
          },
        };
      } else {
        this.widgetOptions = {};
      }
    },
    addToDashboard() {
      this.selectDisplayType(WIDGET_DISPLAY_TYPES.CODE);
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-mb-4 gl-mt-4">
      <div class="gl-flex-direction-column gl-flex-grow-1">
        <input
          v-model="defaultTitle"
          dir="auto"
          type="text"
          :placeholder="s__('ProductAnalytics|New Analytics Widget Title')"
          :aria-label="__('Title')"
          class="form-control gl-border-gray-200"
          data-testid="widget-title-tba"
        />
      </div>
      <div class="gl-ml-2">
        <gl-button category="primary" @click="addToDashboard">{{
          s__('ProductAnalytics|Add to Dashboard')
        }}</gl-button>
      </div>
    </div>
    <div id="js-query-builder-wrapper" class="gl-border-t">
      <query-builder
        ref="builder"
        :cubejs-api="cubejsApi"
        :initial-viz-state="queryState"
        :wrap-with-query-renderer="true"
        :disable-heuristics="true"
        data-testid="query-builder"
      >
        <template
          #builder="{
            measures,
            setMeasures,
            dimensions,
            addDimensions,
            timeDimensions,
            removeDimensions,
            setTimeDimensions,
            removeTimeDimensions,
            filters,
            setFilters,
            addFilters,
          }"
        >
          <div class="gl-mr-4" style="min-width: 360px">
            <measure-selector
              :measures="measures"
              :set-measures="setMeasures"
              :filters="filters"
              :set-filters="setFilters"
              :add-filters="addFilters"
              data-testid="widget-measure-selector"
              @measureSelected="measureUpdated"
            />

            <dimension-selector
              v-if="queryState.measureType && queryState.measureSubType"
              :measure-type="queryState.measureType"
              :measure-sub-type="queryState.measureSubType"
              :dimensions="dimensions"
              :add-dimensions="addDimensions"
              :remove-dimension="removeDimensions"
              :time-dimensions="timeDimensions"
              :set-time-dimensions="setTimeDimensions"
              :remove-time-dimension="removeTimeDimensions"
              data-testid="widget-dimension-selector"
            />
          </div>
        </template>

        <template #default="{ resultSet, isQueryPresent, loading }">
          <div
            class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-bg-gray-10 gl-overflow-auto gl-border-l gl-border-r"
          >
            <widget-preview
              :selected-visualization-type="selectedVisualizationType"
              :display-type="selectedDisplayType"
              :is-query-present="isQueryPresent ? isQueryPresent : false"
              :loading="loading"
              :result-set="resultSet ? resultSet : null"
              :result-widget="resultSet && isQueryPresent ? resultWidget : null"
              @selectedDisplayType="selectDisplayType"
            />
          </div>
          <div class="gl-ml-4" style="min-width: 240px">
            <visualization-inspector
              :selected-visualization-type="selectedVisualizationType"
              @selectVisualizationType="selectVisualizationType"
            />
          </div>
        </template>
      </query-builder>
    </div>
  </div>
</template>
