<script>
import { QueryBuilder } from '@cubejs-client/vue';
import { GlButton } from '@gitlab/ui';

import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { slugify } from '~/lib/utils/text_utility';
import { HTTP_STATUS_CREATED } from '~/lib/utils/http_status';

import { createCubeJsApi } from 'ee/analytics/analytics_dashboards/data_sources/cube_analytics';
import { getPanelOptions } from 'ee/analytics/analytics_dashboards/utils/visualization_panel_options';
import { saveProductAnalyticsVisualization } from 'ee/analytics/analytics_dashboards/api/dashboards_api';
import { NEW_DASHBOARD_SLUG } from 'ee/vue_shared/components/customizable_dashboard/constants';
import {
  PANEL_DISPLAY_TYPES,
  I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER_CUBEJS_ERROR,
  I18N_DASHBOARD_VISUALIZATION_DESIGNER_NAME_ERROR,
  I18N_DASHBOARD_VISUALIZATION_DESIGNER_MEASURE_ERROR,
  I18N_DASHBOARD_VISUALIZATION_DESIGNER_TYPE_ERROR,
  I18N_DASHBOARD_VISUALIZATION_DESIGNER_ALREADY_EXISTS_ERROR,
  I18N_DASHBOARD_VISUALIZATION_DESIGNER_SAVE_ERROR,
  I18N_DASHBOARD_VISUALIZATION_DESIGNER_SAVE_SUCCESS,
} from '../constants';

import MeasureSelector from './visualization_designer/selectors/product_analytics/measure_selector.vue';
import DimensionSelector from './visualization_designer/selectors/product_analytics/dimension_selector.vue';
import VisualizationPreview from './visualization_designer/analytics_visualization_preview.vue';
import VisualizationInspector from './visualization_designer/analytics_visualization_inspector.vue';

export default {
  name: 'AnalyticsVisualizationDesigner',
  components: {
    QueryBuilder,
    GlButton,
    MeasureSelector,
    DimensionSelector,
    VisualizationInspector,
    VisualizationPreview,
  },
  inject: {
    customDashboardsProject: {
      type: Object,
      default: null,
    },
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
      visualizationName: '',
      selectedDisplayType: PANEL_DISPLAY_TYPES.DATA,
      selectedVisualizationType: '',
      hasTimeDimension: false,
      isSaving: false,
      alert: null,
    };
  },
  computed: {
    resultVisualization() {
      const newCubeQuery = this.$refs.builder.$children[0].resultSet.query();

      // Weird behaviour as the API says its malformed if we send it again
      delete newCubeQuery.order;
      delete newCubeQuery.rowLimit;
      delete newCubeQuery.queryType;

      return {
        version: 1,
        type: this.selectedVisualizationType,
        data: {
          type: 'cube_analytics',
          query: newCubeQuery,
        },
        options: this.panelOptions,
      };
    },
    panelOptions() {
      return getPanelOptions(this.selectedVisualizationType, this.hasTimeDimension);
    },
    saveButtonText() {
      return this.$route?.params.dashboardid
        ? s__('Analytics|Save and add to Dashboard')
        : s__('Analytics|Save new visualization');
    },
  },
  beforeDestroy() {
    this.alert?.dismiss();
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
    onQueryStatusChange({ error }) {
      if (!error) {
        this.alert?.dismiss();
        return;
      }

      this.showAlert(I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER_CUBEJS_ERROR, error, true);
    },
    onVizStateChange(state) {
      this.hasTimeDimension = Boolean(state.query.timeDimensions?.length);
    },
    measureUpdated(measureType, measureSubType) {
      this.queryState.measureType = measureType;
      this.queryState.measureSubType = measureSubType;
    },
    selectDisplayType(newType) {
      this.selectedDisplayType = newType;
    },
    selectVisualizationType(newType) {
      this.selectDisplayType(PANEL_DISPLAY_TYPES.VISUALIZATION);
      this.selectedVisualizationType = newType;
    },
    getSaveVisualizationValidationError() {
      if (!this.visualizationName) {
        return I18N_DASHBOARD_VISUALIZATION_DESIGNER_NAME_ERROR;
      }
      if (!this.selectedVisualizationType) {
        return I18N_DASHBOARD_VISUALIZATION_DESIGNER_TYPE_ERROR;
      }
      if (!this.queryState.measureSubType) {
        return I18N_DASHBOARD_VISUALIZATION_DESIGNER_MEASURE_ERROR;
      }
      return null;
    },
    async saveVisualization() {
      const validationError = this.getSaveVisualizationValidationError();

      if (validationError) {
        this.showAlert(validationError);
        return;
      }

      this.isSaving = true;

      try {
        const filename = slugify(this.visualizationName, '_');

        const saveResult = await saveProductAnalyticsVisualization(
          filename,
          this.resultVisualization,
          this.customDashboardsProject,
        );

        if (saveResult.status === HTTP_STATUS_CREATED) {
          this.alert?.dismiss();

          this.$toast.show(I18N_DASHBOARD_VISUALIZATION_DESIGNER_SAVE_SUCCESS);

          if (this.$route?.params.dashboard) {
            this.routeToDashboard(this.$route?.params.dashboard);
          }
        } else {
          this.showAlert(
            I18N_DASHBOARD_VISUALIZATION_DESIGNER_SAVE_ERROR,
            new Error(
              `Recieved an unexpected HTTP status while saving visualization: ${saveResult.status}`,
            ),
            true,
          );
        }
      } catch (error) {
        const { message = '' } = error?.response?.data || {};

        // eslint-disable-next-line @gitlab/require-i18n-strings
        if (message === 'A file with this name already exists') {
          this.showAlert(I18N_DASHBOARD_VISUALIZATION_DESIGNER_ALREADY_EXISTS_ERROR);
        } else {
          this.showAlert(
            `${I18N_DASHBOARD_VISUALIZATION_DESIGNER_SAVE_ERROR} ${message}`.trimEnd(),
            error,
            true,
          );
        }
      } finally {
        this.isSaving = false;
      }
    },
    routeToDashboard(dashboard) {
      if (dashboard === NEW_DASHBOARD_SLUG) {
        this.$router.push('/new');
      } else {
        this.$router.push({
          name: 'dashboard-detail',
          params: {
            slug: dashboard,
            editing: true,
          },
        });
      }
    },
    showAlert(message, error = null, captureError = false) {
      this.alert = createAlert({
        message,
        error,
        captureError,
      });
    },
  },
  I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER_CUBEJS_ERROR,
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-mb-4 gl-mt-4">
      <div class="gl-flex-direction-column gl-flex-grow-1">
        <input
          v-model="visualizationName"
          dir="auto"
          type="text"
          :placeholder="s__('Analytics|New analytics visualization name')"
          :aria-label="__('Name')"
          class="form-control gl-border-gray-200"
          data-testid="panel-title-tba"
        />
      </div>
      <div class="gl-ml-2">
        <gl-button
          :loading="isSaving"
          category="primary"
          variant="confirm"
          data-testid="visualization-save-btn"
          @click="saveVisualization"
          >{{ saveButtonText }}</gl-button
        >
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
        @queryStatus="onQueryStatusChange"
        @vizStateChange="onVizStateChange"
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
              data-testid="panel-measure-selector"
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
              data-testid="panel-dimension-selector"
            />
          </div>
        </template>

        <template #default="{ resultSet, isQueryPresent, loading }">
          <div
            class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-bg-gray-10 gl-overflow-auto gl-border-l gl-border-r"
          >
            <visualization-preview
              :selected-visualization-type="selectedVisualizationType"
              :display-type="selectedDisplayType"
              :is-query-present="isQueryPresent ? isQueryPresent : false"
              :loading="loading"
              :result-set="resultSet ? resultSet : null"
              :result-visualization="resultSet && isQueryPresent ? resultVisualization : null"
              :title="visualizationName"
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
