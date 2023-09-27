<script>
import { GridStack } from 'gridstack';
import * as Sentry from '@sentry/browser';
import { GlButton, GlFormInput, GlFormGroup, GlLink, GlIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { cloneWithoutReferences } from '~/lib/utils/common_utils';
import { loadCSSFile } from '~/lib/utils/css_utils';
import { slugify } from '~/lib/utils/text_utility';
import { s__ } from '~/locale';
import UrlSync, { HISTORY_REPLACE_UPDATE_METHOD } from '~/vue_shared/components/url_sync.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { createNewVisualizationPanel } from 'ee/analytics/analytics_dashboards/utils';
import PanelsBase from './panels_base.vue';
import {
  GRIDSTACK_MARGIN,
  GRIDSTACK_CSS_HANDLE,
  GRIDSTACK_CELL_HEIGHT,
  GRIDSTACK_MIN_ROW,
  CURSOR_GRABBING_CLASS,
  DASHBOARD_DOCUMENTATION_LINKS,
} from './constants';
import AvailableVisualizationsDrawer from './dashboard_editor/available_visualizations_drawer.vue';
import { filtersToQueryParams, getUniquePanelId, availableVisualizationsValidator } from './utils';

export default {
  name: 'CustomizableDashboard',
  components: {
    DateRangeFilter: () => import('./filters/date_range_filter.vue'),
    GlButton,
    GlFormInput,
    GlIcon,
    GlLink,
    GlFormGroup,
    PanelsBase,
    UrlSync,
    AvailableVisualizationsDrawer,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    initialDashboard: {
      type: Object,
      required: true,
      default: () => {},
    },
    availableVisualizations: {
      type: Object,
      required: false,
      default: () => {},
      validator: availableVisualizationsValidator,
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
      default: false,
    },
    isSaving: {
      type: Boolean,
      required: false,
      default: false,
    },
    changesSaved: {
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
    const dashboard = cloneWithoutReferences(this.initialDashboard);
    dashboard.panels = dashboard.panels.map((panel) => ({
      ...panel,
      id: getUniquePanelId(),
    }));

    return {
      dashboard,
      grid: undefined,
      cssLoaded: false,
      mounted: true,
      editing: this.isNewDashboard,
      filters: this.defaultFilters,
      alert: null,
      titleValidationState: null,
      visualizationDrawerOpen: false,
    };
  },
  computed: {
    loaded() {
      return this.cssLoaded && this.mounted;
    },
    showFilters() {
      return this.showDateRangeFilter && !this.editing;
    },
    queryParams() {
      return this.showFilters ? filtersToQueryParams(this.filters) : {};
    },
    editingEnabled() {
      return this.glFeatures.combinedAnalyticsDashboardsEditor && this.dashboard.userDefined;
    },
    showEditControls() {
      return this.editingEnabled && this.editing;
    },
    showGrid() {
      return this.dashboard.panels.length > 0;
    },
    showDashboardDescription() {
      return Boolean(this.dashboard.description) && !this.editing;
    },
    showEditDashboardButton() {
      return this.editingEnabled && !this.editing;
    },
    dashboardDescription() {
      return this.dashboard.description;
    },
    documentationLink() {
      return DASHBOARD_DOCUMENTATION_LINKS[this.dashboard.slug];
    },
  },
  watch: {
    cssLoaded() {
      this.initGridStack();
    },
    mounted() {
      this.initGridStack();
    },
    isNewDashboard(isNew) {
      this.editing = isNew;
    },
    changesSaved: {
      handler(saved) {
        if (saved && this.editing) {
          this.editing = false;
        }
      },
      immediate: true,
    },
    '$route.params.editing': {
      handler(editing) {
        if (editing !== undefined) {
          this.editing = editing;
        }
      },
      immediate: true,
    },
    editing(editing) {
      this.grid?.setStatic(!editing);
      if (!editing) {
        this.closeVisualizationDrawer();
      }
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

    this.alert?.dismiss();
  },
  methods: {
    onTitleInput() {
      // Don't validate if the title has not been submitted
      if (this.titleValidationState !== null) {
        this.titleValidationState = this.dashboard.title.length > 0;
      }
    },
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
    registerNewGridPanel(panelId) {
      this.grid.makeWidget(`#${panelId}`);

      document.getElementById(panelId)?.scrollIntoView({ behavior: 'smooth' });
    },
    getGridAttribute(panel, attribute) {
      const { gridAttributes = {} } = panel;

      return gridAttributes[attribute];
    },
    async addSelectedVisualizations(selected) {
      const panelIds = selected.map((visualization) => {
        const panel = createNewVisualizationPanel(visualization);
        this.dashboard.panels.push(panel);
        return panel.id;
      });

      // Wait for the panels to render
      await this.$nextTick();

      panelIds.forEach((id) => this.registerNewGridPanel(id));
      this.closeVisualizationDrawer();
    },
    async deletePanel(panel) {
      const panelIndex = this.dashboard.panels.indexOf(panel);
      this.dashboard.panels.splice(panelIndex, 1);

      this.grid.removeWidget(document.getElementById(panel.id), false);
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
      this.editing = true;
    },
    async saveEdit() {
      this.titleValidationState = this.dashboard.title.length > 0;

      if (!this.titleValidationState) {
        this.$refs.titleInput.$el.focus();
        return;
      }

      if (this.isNewDashboard && this.dashboard.panels.length < 1) {
        this.alert = createAlert({
          message: s__('Analytics|Add a visualization'),
        });
        return;
      }

      this.alert?.dismiss();

      if (this.isNewDashboard) {
        this.dashboard.slug = slugify(this.dashboard.title, '_');
      }

      this.$emit('save', this.dashboard.slug, this.dashboard);
    },
    cancelEdit() {
      if (this.isNewDashboard) {
        this.$router.push('/');
        return;
      }

      this.editing = false;
    },
    updatePanelWithGridStackItem(item) {
      const updatedPanel = this.dashboard.panels.find((panel) => panel.id === item.id);
      if (updatedPanel) {
        updatedPanel.gridAttributes = this.convertToGridAttributes(item);
      }
    },
    setDateRangeFilter({ dateRangeOption, startDate, endDate }) {
      this.filters = {
        ...this.filters,
        dateRangeOption,
        startDate,
        endDate,
      };
    },
    toggleVisualizationDrawer() {
      this.visualizationDrawerOpen = !this.visualizationDrawerOpen;
    },
    closeVisualizationDrawer() {
      this.visualizationDrawerOpen = false;
    },
  },
  HISTORY_REPLACE_UPDATE_METHOD,
};
</script>

<template>
  <div>
    <section class="gl-display-flex gl-align-items-center gl-py-6">
      <div class="gl-display-flex gl-flex-direction-column gl-w-full">
        <h2 v-if="showEditControls" data-testid="edit-mode-title" class="gl-mt-0 gl-mb-6">
          {{
            isNewDashboard
              ? s__('Analytics|Create your dashboard')
              : s__('Analytics|Edit your dashboard')
          }}
        </h2>
        <h2 v-else data-testid="dashboard-title" class="gl-my-0">{{ dashboard.title }}</h2>
        <div
          v-if="showDashboardDescription"
          class="gl-display-flex gl-mt-5"
          data-testid="dashboard-description"
        >
          <p class="gl-mb-0">
            {{ dashboardDescription }}
            <gl-link v-if="documentationLink" :href="documentationLink" rel="noopener">
              {{ __('Learn more') }}
            </gl-link>
          </p>
        </div>

        <div v-if="showEditControls" class="gl-display-flex flex-fill">
          <gl-form-group
            :label="s__('Analytics|Dashboard title')"
            label-for="title"
            class="gl-w-30p gl-min-w-20 gl-m-0 gl-xs-w-full"
            data-testid="dashboard-title-form-group"
            :invalid-feedback="__('This field is required.')"
            :state="titleValidationState"
          >
            <gl-form-input
              id="title"
              ref="titleInput"
              v-model="dashboard.title"
              dir="auto"
              type="text"
              :placeholder="s__('Analytics|Enter a dashboard title')"
              :aria-label="s__('Analytics|Dashboard title')"
              class="form-control gl-mr-4 gl-border-gray-200"
              data-testid="dashboard-title-input"
              :state="titleValidationState"
              required
              @input="onTitleInput"
            />
          </gl-form-group>
        </div>
      </div>

      <gl-button
        v-if="showEditDashboardButton"
        icon="pencil"
        class="gl-mr-2"
        data-testid="dashboard-edit-btn"
        @click="startEdit"
        >{{ s__('Analytics|Edit') }}</gl-button
      >
    </section>
    <div
      class="grid-stack-container gl-mx-n5 gl-pl-2 gl-pr-2 gl-border-t-1 gl-border-t-solid gl-border-t-gray-100"
    >
      <div class="grid-stack-container gl-display-flex">
        <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-py-3">
          <section
            v-if="showFilters"
            data-testid="dashboard-filters"
            class="gl-display-flex gl-pt-4 gl-px-3 gl-justify-content-space-between"
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
          <button
            v-if="showEditControls"
            class="card upload-dropzone-card upload-dropzone-border gl-display-flex gl-align-items-center gl-px-5 gl-py-3 gl-my-3 gl-mx-4"
            data-testid="add-visualization-button"
            @click="toggleVisualizationDrawer"
          >
            <div class="gl-font-weight-bold gl-text-gray-700 gl-display-flex gl-align-items-center">
              <div
                class="gl-h-7 gl-w-7 gl-rounded-full gl-bg-gray-100 gl-display-inline-flex gl-align-items-center gl-justify-content-center gl-mr-3"
              >
                <gl-icon name="plus" />
              </div>
              {{ s__('Analytics|Add visualization') }}
            </div>
          </button>
          <div data-testid="gridstack-grid" class="grid-stack">
            <div
              v-for="panel in dashboard.panels"
              :id="panel.id"
              :key="panel.id"
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
                :query-overrides="panel.queryOverrides || undefined"
                :filters="filters"
                :editing="editing"
                @delete="deletePanel(panel)"
              />
            </div>
          </div>
        </div>
        <available-visualizations-drawer
          :visualizations="availableVisualizations.visualizations"
          :loading="availableVisualizations.loading"
          :has-error="availableVisualizations.hasError"
          :open="visualizationDrawerOpen"
          @select="addSelectedVisualizations"
          @close="closeVisualizationDrawer"
        />
      </div>
    </div>
    <template v-if="editing">
      <gl-button
        :loading="isSaving"
        class="gl-my-4 gl-mr-2"
        category="primary"
        variant="confirm"
        data-testid="dashboard-save-btn"
        @click="saveEdit"
        >{{ s__('Analytics|Save your dashboard') }}</gl-button
      >
      <gl-button category="secondary" data-testid="dashboard-cancel-edit-btn" @click="cancelEdit">{{
        s__('Analytics|Cancel')
      }}</gl-button>
    </template>
  </div>
</template>
