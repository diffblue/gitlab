<script>
import { GridStack } from 'gridstack';
import * as Sentry from '@sentry/browser';
import { GlButton, GlFormInput, GlEmptyState, GlFormGroup, GlLink } from '@gitlab/ui';
import { createAlert } from '~/alert';
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
  NEW_DASHBOARD_SLUG,
  DASHBOARD_DOCUMENTATION_LINKS,
} from './constants';
import VisualizationSelector from './dashboard_editor/visualization_selector.vue';
import { filtersToQueryParams } from './utils';

export default {
  name: 'CustomizableDashboard',
  components: {
    DateRangeFilter: () => import('./filters/date_range_filter.vue'),
    GlButton,
    GlFormInput,
    GlLink,
    GlEmptyState,
    GlFormGroup,
    PanelsBase,
    UrlSync,
    VisualizationSelector,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    dashboardEmptyStateIllustrationPath: {
      type: Object,
      default: null,
    },
  },
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
    return {
      dashboard: JSON.parse(JSON.stringify(this.initialDashboard)),
      grid: undefined,
      cssLoaded: false,
      mounted: true,
      editing: this.isNewDashboard,
      filters: this.defaultFilters,
      alert: null,
      titleValidationState: null,
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
    showEmptyState() {
      return this.dashboard.panels.length < 1 && this.showEditControls && this.isNewDashboard;
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
    registerNewGridPanel(panelIndex) {
      const domId = this.panelDomId(panelIndex);

      this.grid.makeWidget(`#${domId}`);

      document.getElementById(domId)?.scrollIntoView({ behavior: 'smooth' });
    },
    getGridAttribute(panel, attribute) {
      const { gridAttributes = {} } = panel;

      return gridAttributes[attribute];
    },
    async addNewPanel(visualization) {
      const panel = createNewVisualizationPanel(visualization);
      this.dashboard.panels.push(panel);

      // Wait for the panels to render
      await this.$nextTick();
      this.registerNewGridPanel(this.dashboard.panels.length - 1);
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
    routeToVisualizationDesigner() {
      const dashboard = this.isNewDashboard ? NEW_DASHBOARD_SLUG : this.dashboard.slug;
      this.$router.push({ name: 'visualization-designer', params: { dashboard } });
    },
    async saveEdit() {
      this.titleValidationState = this.dashboard.title.length > 0;

      if (!this.titleValidationState) {
        this.$refs.titleInput.$el.focus();
        return;
      }

      if (this.dashboard.panels.length < 1) {
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
      const updatedPanel = this.dashboard.panels.at(Number(item.id));
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
    panelDomId(id) {
      return `panel-${id}`;
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
        <div
          class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-py-3"
          :class="{ 'gl-justify-content-center': !dashboard.panels.length }"
        >
          <gl-empty-state
            v-if="showEmptyState"
            class="gl-m-0 gl-mt-20"
            :svg-path="dashboardEmptyStateIllustrationPath"
            :title="s__('Analytics|Add a visualization')"
            :description="s__('Analytics|Select a visualization from the sidebar to get started.')"
          />
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
          <div v-show="!showEmptyState" data-testid="gridstack-grid" class="grid-stack">
            <div
              v-for="(panel, index) in dashboard.panels"
              :id="panelDomId(index)"
              :key="index"
              :gs-id="index"
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
              />
            </div>
          </div>
        </div>
        <div
          v-if="editing"
          class="gl-ml-4 gl-p-4 gl-bg-white gl-border-l gl-overflow-auto gl-w-full gl-max-w-34"
        >
          <h5>{{ s__('Analytics|Add visualizations') }}</h5>
          <visualization-selector
            class="gl-border-t gl-pt-2"
            :available-visualizations="availableVisualizations"
            @select="addNewPanel"
            @create="routeToVisualizationDesigner"
          />
        </div>
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
