<script>
import { GlButton, GlButtonGroup, GlLoadingIcon } from '@gitlab/ui';
import PanelsBase from 'ee/vue_shared/components/customizable_dashboard/panels_base.vue';
import { createAlert } from '~/flash';
import { s__, sprintf } from '~/locale';

import DataTable from 'ee/product_analytics/dashboards/components/visualizations/data_table.vue';

import { PANEL_DISPLAY_TYPES, PANEL_DISPLAY_TYPE_ITEMS } from '../../constants';

export default {
  name: 'AnalyticsPanelPreview',

  PANEL_DISPLAY_TYPES,
  PANEL_DISPLAY_TYPE_ITEMS,
  components: {
    GlButton,
    GlButtonGroup,
    GlLoadingIcon,
    PanelsBase,
    DataTable,
  },
  props: {
    selectedVisualizationType: {
      type: String,
      required: true,
    },
    displayType: {
      type: String,
      required: true,
    },
    isQueryPresent: {
      type: Boolean,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
    resultSet: {
      type: Object,
      required: false,
      default: null,
    },
    resultPanel: {
      type: Object,
      required: false,
      default: null,
    },
  },
  methods: {
    handlePanelError(panelTitle, error) {
      createAlert({
        message: sprintf(
          s__('ProductAnalytics|An error occured while loading the %{panelTitle} panel.'),
          { panelTitle },
        ),
        error,
        captureError: true,
      });
    },
  },
};
</script>

<template>
  <div>
    <div v-if="!isQueryPresent || loading">
      <div class="col-12 gl-mt-4">
        <div class="text-content text-center gl-text-gray-400">
          <h3 v-if="!isQueryPresent" data-testid="measurement-hl" class="gl-text-gray-400">
            {{ s__('ProductAnalytics|Choose a measurement to start') }}
          </h3>
          <gl-loading-icon
            v-else-if="loading"
            size="lg"
            class="gl-mt-6"
            data-testid="loading-icon"
          />
        </div>
      </div>
    </div>
    <div v-if="resultSet && isQueryPresent" class="border-light">
      <div class="container gl-mt-3 gl-mb-3">
        <div class="row">
          <div class="col-6">
            <gl-button-group>
              <gl-button
                v-for="buttonDisplayType in $options.PANEL_DISPLAY_TYPE_ITEMS"
                :key="buttonDisplayType.type"
                :selected="displayType === buttonDisplayType.type"
                :icon="buttonDisplayType.icon"
                :data-testid="`select-${buttonDisplayType.type}-button`"
                @click="$emit('selectedDisplayType', buttonDisplayType.type)"
                >{{ buttonDisplayType.title }}</gl-button
              >
            </gl-button-group>
          </div>
        </div>
      </div>
      <div
        v-if="displayType === $options.PANEL_DISPLAY_TYPES.DATA"
        class="grid-stack-item gl-m-5"
        data-testid="grid-stack-panel"
      >
        <div
          class="grid-stack-item-content gl-shadow gl-rounded-base gl-p-4 gl-display-flex gl-flex-direction-column gl-bg-white"
        >
          <strong class="gl-mb-2">{{ s__('ProductAnalytics|Resulting Data') }}</strong>
          <div class="gl-overflow-y-auto gl-h-full">
            <!-- Using Datatable specifically for data preview here -->
            <data-table
              :data="resultSet.tablePivot()"
              data-testid="preview-datatable"
              @error="(error) => handlePanelError('TITLE', error)"
            />
          </div>
        </div>
      </div>

      <div
        v-if="displayType === $options.PANEL_DISPLAY_TYPES.PANEL"
        class="grid-stack-item gl-m-5"
        data-testid="grid-stack-panel"
      >
        <panels-base
          v-if="selectedVisualizationType"
          :title="resultPanel.title"
          :visualization="resultPanel"
          data-testid="preview-panel"
          @error="(error) => handlePanelError('TITLE', error)"
        />
        <div v-else class="col-12 gl-mt-4">
          <div class="text-content text-center gl-text-gray-400">
            <h3 class="gl-text-gray-400">
              {{ s__('ProductAnalytics|Choose a chart type on the right') }}
            </h3>
          </div>
        </div>
      </div>

      <div v-if="displayType === $options.PANEL_DISPLAY_TYPES.CODE" class="gl-m-4">
        <pre
          class="code highlight gl-display-flex gl-bg-white"
          data-testid="preview-code"
        ><code>{{ resultPanel }}</code></pre>
      </div>
    </div>
  </div>
</template>
