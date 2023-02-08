<script>
import { GridStack } from 'gridstack';
import * as Sentry from '@sentry/browser';
import { GlButton } from '@gitlab/ui';
import { loadCSSFile } from '~/lib/utils/css_utils';
import { createAlert } from '~/flash';
import { s__, sprintf } from '~/locale';
import UrlSync, { HISTORY_REPLACE_UPDATE_METHOD } from '~/vue_shared/components/url_sync.vue';
import PanelsBase from './panels_base.vue';
import { GRIDSTACK_MARGIN, GRIDSTACK_CSS_HANDLE } from './constants';
import { filtersToQueryParams } from './utils';

export default {
  name: 'CustomizableDashboard',
  components: {
    DateRangeFilter: () => import('./filters/date_range_filter.vue'),
    GlButton,
    PanelsBase,
    UrlSync,
  },
  props: {
    initialDashboard: {
      type: Object,
      required: true,
      default: () => {},
    },
    getVisualization: {
      type: Function,
      required: false,
      default: () => {},
    },
    availableVisualizations: {
      type: Array,
      required: true,
    },
    showDateRangeFilter: {
      type: Boolean,
      required: false,
      default: false,
    },
    defaultFilters: {
      type: Object,
      required: false,
      default: () => {},
    },
    syncUrlFilters: {
      type: Boolean,
      required: false,
      default: () => {},
    },
  },
  data() {
    return {
      dashboard: { ...this.initialDashboard },
      grid: undefined,
      cssLoaded: false,
      mounted: true,
      editing: false,
      showCode: false,
      filters: this.defaultFilters,
    };
  },
  computed: {
    loaded() {
      return this.cssLoaded && this.mounted;
    },
    showCodeVariant() {
      return this.showCode ? 'confirm' : 'default';
    },
    showFilters() {
      return this.showDateRangeFilter;
    },
    queryParams() {
      return filtersToQueryParams(this.filters);
    },
  },
  watch: {
    cssLoaded() {
      this.initGridStack();
    },
    mounted() {
      this.initGridStack();
    },
  },
  async created() {
    try {
      await loadCSSFile(gon.gridstack_css_path);
      this.cssLoaded = true;
    } catch (e) {
      Sentry.captureException(e);
    }
  },
  mounted() {
    this.mounted = true;

    const wrappers = document.querySelectorAll('.container-fluid.container-limited');

    wrappers.forEach((el) => {
      el.classList.remove('container-limited');
    });
  },
  unmounted() {
    this.mounted = false;
  },
  methods: {
    initGridStack() {
      if (this.loaded) {
        this.grid = GridStack.init({
          staticGrid: !this.editing,
          margin: GRIDSTACK_MARGIN,
          handle: GRIDSTACK_CSS_HANDLE,
          minRow: 1,
        });

        this.grid.on('change', (event, items) => {
          items.forEach((item) => {
            this.updatePanelWithGridStackItem(item);
          });
        });
        this.grid.on('added', (event, items) => {
          items.forEach((item) => {
            this.updatePanelWithGridStackItem(item);
          });
        });
      }
    },
    getGridAttribute(panel, attribute) {
      const { gridAttributes = {} } = panel;

      return gridAttributes[attribute];
    },
    convertToGridAttributes(gridStackProperties) {
      return {
        yPos: gridStackProperties.y,
        xPos: gridStackProperties.x,
        width: gridStackProperties.w,
        height: gridStackProperties.h,
      };
    },
    startEdit() {
      if (!this.editing) {
        this.editing = true;
        if (this.grid) this.grid.setStatic(false);
      }
    },
    async saveEdit() {
      // Only showing code until we can actually save
      this.toggleCodeDisplay();
    },
    cancelEdit() {
      this.editing = false;
      if (this.grid) this.grid.setStatic(true);
    },
    async toggleCodeDisplay() {
      this.showCode = !this.showCode;
      if (!this.showCode) {
        setTimeout(() => {
          this.initGridStack();
        }, 200);
      } else {
        this.grid.destroy();
      }
    },
    updatePanelWithGridStackItem(item) {
      const updatedPanel = this.dashboard.panels.find((element) => element.id === Number(item.id));
      if (updatedPanel) {
        updatedPanel.gridAttributes = this.convertToGridAttributes(item);
      }
      const selectedDefaultPanel = this.dashboard.default.panels.find(
        (element) => element.id === Number(item.id),
      );
      if (selectedDefaultPanel) {
        selectedDefaultPanel.gridAttributes = this.convertToGridAttributes(item);
      }
    },
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
    setDateRangeFilter({ dateRangeOption, startDate, endDate }) {
      this.filters = {
        ...this.filters,
        dateRangeOption,
        startDate,
        endDate,
      };
    },
  },
  HISTORY_REPLACE_UPDATE_METHOD,
};
</script>

<template>
  <div>
    <section
      class="gl-display-flex gl-align-items-center gl-py-5 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
    >
      <h3 class="gl-my-0 flex-fill">{{ dashboard.title }}</h3>
      <gl-button
        v-if="!editing"
        icon="pencil"
        class="gl-mr-2"
        data-testid="dashboard-edit-btn"
        @click="startEdit"
        >{{ s__('ProductAnalytics|Edit') }}</gl-button
      >
      <gl-button
        v-if="editing"
        :variant="showCodeVariant"
        icon="code"
        class="gl-mr-2"
        data-testid="dashboard-code-btn"
        @click="toggleCodeDisplay"
        >{{ s__('ProductAnalytics|Code') }}</gl-button
      >
      <gl-button
        v-if="editing"
        class="gl-mr-2"
        category="secondary"
        data-testid="dashboard-cancel-edit-btn"
        @click="cancelEdit"
        >{{ s__('ProductAnalytics|Cancel Edit') }}</gl-button
      >
      <router-link v-if="!editing" to="/" class="gl-button btn btn-default btn-md">
        {{ s__('ProductAnalytics|Go back') }}
      </router-link>
    </section>
    <div class="gl-bg-gray-10">
      <section
        v-if="showFilters"
        data-testid="dashboard-filters"
        class="gl-pt-6 gl-px-3 gl-display-flex"
      >
        <date-range-filter
          v-if="showDateRangeFilter"
          :default-option="filters.dateRangeOption"
          :start-date="filters.startDate"
          :end-date="filters.endDate"
          @change="setDateRangeFilter"
        />
      </section>
      <url-sync
        v-if="syncUrlFilters"
        :query="queryParams"
        :history-update-method="$options.HISTORY_REPLACE_UPDATE_METHOD"
      />
      <div class="grid-stack-container gl-display-flex">
        <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-py-6">
          <div v-if="!showCode" class="grid-stack">
            <div
              v-for="(panel, index) in dashboard.panels"
              :id="'panel-' + panel.id"
              :key="index"
              :gs-id="panel.id"
              :gs-x="getGridAttribute(panel, 'xPos')"
              :gs-y="getGridAttribute(panel, 'yPos')"
              :gs-h="getGridAttribute(panel, 'height')"
              :gs-w="getGridAttribute(panel, 'width')"
              :gs-min-h="getGridAttribute(panel, 'minHeight')"
              :gs-min-w="getGridAttribute(panel, 'minWidth')"
              :gs-max-h="getGridAttribute(panel, 'maxHeight')"
              :gs-max-w="getGridAttribute(panel, 'maxWidth')"
              class="grid-stack-item"
              data-testid="grid-stack-panel"
            >
              <panels-base
                :title="panel.title"
                :visualization="panel.visualization"
                :query-overrides="panel.queryOverrides"
                :filters="filters"
                @error="handlePanelError(panel.title, $event)"
              />
            </div>
          </div>
          <div v-if="showCode" class="gl-m-4">
            <pre
              class="code highlight gl-display-flex"
            ><code data-testid="dashboard-code">{{ dashboard.default }}</code></pre>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
