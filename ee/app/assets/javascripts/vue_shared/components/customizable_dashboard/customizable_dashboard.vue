<script>
import { GridStack } from 'gridstack';
import * as Sentry from '@sentry/browser';
import { GlButton, GlFormInput, GlForm } from '@gitlab/ui';
import { loadCSSFile } from '~/lib/utils/css_utils';
import { slugify } from '~/lib/utils/text_utility';
import { createAlert } from '~/alert';
import { s__, sprintf } from '~/locale';
import UrlSync, { HISTORY_REPLACE_UPDATE_METHOD } from '~/vue_shared/components/url_sync.vue';
import PanelsBase from './panels_base.vue';
import {
  GRIDSTACK_MARGIN,
  GRIDSTACK_CSS_HANDLE,
  GRIDSTACK_CELL_HEIGHT,
  GRIDSTACK_MIN_ROW,
  CURSOR_GRABBING_CLASS,
} from './constants';
import { filtersToQueryParams } from './utils';

export default {
  name: 'CustomizableDashboard',
  components: {
    DateRangeFilter: () => import('./filters/date_range_filter.vue'),
    GlButton,
    GlFormInput,
    GlForm,
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
    dateRangeLimit: {
      type: Number,
      required: false,
      default: 0,
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
    isSaving: {
      type: Boolean,
      required: false,
      default: false,
    },
    isNewDashboard: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      dashboard: { ...this.initialDashboard },
      grid: undefined,
      cssLoaded: false,
      mounted: true,
      editing: this.isNewDashboard,
      showCode: false,
      filters: this.defaultFilters,
    };
  },
  computed: {
    loaded() {
      return this.cssLoaded && this.mounted;
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
      el.classList.add('not-container-limited');
      el.classList.remove('container-limited');
    });
  },
  beforeDestroy() {
    this.mounted = false;

    const wrappers = document.querySelectorAll('.container-fluid.not-container-limited');

    wrappers.forEach((el) => {
      el.classList.add('container-limited');
      el.classList.remove('not-container-limited');
    });
  },
  methods: {
    initGridStack() {
      if (this.loaded) {
        this.grid = GridStack.init({
          staticGrid: !this.editing,
          margin: GRIDSTACK_MARGIN,
          handle: GRIDSTACK_CSS_HANDLE,
          cellHeight: GRIDSTACK_CELL_HEIGHT,
          minRow: GRIDSTACK_MIN_ROW,
          alwaysShowResizeHandle: true,
        });

        this.grid.on('dragstart', () => {
          this.$el.classList.add(CURSOR_GRABBING_CLASS);
        });
        this.grid.on('dragstop', () => {
          this.$el.classList.remove(CURSOR_GRABBING_CLASS);
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
    async saveEdit(submitEvent) {
      submitEvent.preventDefault();

      if (!this.dashboard.id) {
        this.dashboard.id = slugify(this.dashboard.title, '_');
      }

      if (this.isNewDashboard) {
        this.showCode = false;
      }

      // Copying over to our original dashboard object
      // as the main one was hydrated during load with other file
      this.dashboard.default.id = this.dashboard.id;
      this.dashboard.default.title = this.dashboard.title;
      this.$emit('save', this.dashboard.id, this.dashboard.default);
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
    <section class="gl-display-flex gl-align-items-center gl-py-5">
      <h3 v-if="!editing" class="gl-my-0 flex-fill">{{ dashboard.title }}</h3>
      <gl-form v-else class="gl-display-flex flex-fill" @submit="saveEdit">
        <gl-form-input
          v-model="dashboard.title"
          dir="auto"
          type="text"
          :placeholder="s__('Analytics|Dashboard Title')"
          :aria-label="s__('Analytics|Dashboard Title')"
          class="form-control gl-mr-4 gl-border-gray-200"
          data-testid="dashboard-title-tb"
          required
        />
        <gl-button
          :loading="isSaving"
          class="gl-mr-2"
          category="primary"
          variant="confirm"
          data-testid="dashboard-save-btn"
          type="submit"
          >{{ s__('Analytics|Save') }}</gl-button
        >
      </gl-form>
      <gl-button
        v-if="!editing && !dashboard.builtin"
        icon="pencil"
        class="gl-mr-2"
        data-testid="dashboard-edit-btn"
        @click="startEdit"
        >{{ s__('Analytics|Edit') }}</gl-button
      >
      <gl-button
        v-if="editing || dashboard.builtin"
        :selected="showCode"
        icon="code"
        class="gl-mr-2"
        data-testid="dashboard-code-btn"
        @click="toggleCodeDisplay"
        >{{ s__('Analytics|Code') }}</gl-button
      >
      <gl-button
        v-if="editing && !isNewDashboard"
        class="gl-mr-2"
        category="secondary"
        data-testid="dashboard-cancel-edit-btn"
        @click="cancelEdit"
        >{{ s__('Analytics|Cancel') }}</gl-button
      >
      <router-link
        v-if="!editing || isNewDashboard"
        to="/"
        class="gl-button btn btn-default btn-md"
      >
        {{ s__('ProductAnalytics|Go back') }}
      </router-link>
    </section>
    <div
      class="grid-stack-container gl-mx-n5 gl-pl-2 gl-pr-2 gl-bg-gray-10 gl-border-t-1 gl-border-t-solid gl-border-t-gray-100"
    >
      <section
        v-if="showFilters"
        data-testid="dashboard-filters"
        class="gl-display-flex gl-pt-4 gl-px-3"
      >
        <date-range-filter
          v-if="showDateRangeFilter"
          :default-option="filters.dateRangeOption"
          :start-date="filters.startDate"
          :end-date="filters.endDate"
          :date-range-limit="dateRangeLimit"
          @change="setDateRangeFilter"
        />
      </section>
      <url-sync
        v-if="syncUrlFilters"
        :query="queryParams"
        :history-update-method="$options.HISTORY_REPLACE_UPDATE_METHOD"
      />
      <div class="grid-stack-container gl-display-flex">
        <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-py-3">
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
              :class="{ 'gl-cursor-grab': editing }"
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
