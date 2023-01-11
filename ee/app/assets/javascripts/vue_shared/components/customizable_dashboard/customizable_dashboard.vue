<script>
import { GridStack } from 'gridstack';
import * as Sentry from '@sentry/browser';
import { GlButton } from '@gitlab/ui';
import { loadCSSFile } from '~/lib/utils/css_utils';
import { createAlert } from '~/flash';
import { s__, sprintf } from '~/locale';
import WidgetsBase from './widgets_base.vue';
import { GRIDSTACK_MARGIN, GRIDSTACK_CSS_HANDLE } from './constants';

export default {
  name: 'CustomizableDashboard',
  components: {
    GlButton,
    WidgetsBase,
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
  },
  data() {
    return {
      dashboard: { ...this.initialDashboard },
      grid: undefined,
      cssLoaded: false,
      mounted: true,
      editing: false,
      showCode: false,
    };
  },
  computed: {
    loaded() {
      return this.cssLoaded && this.mounted;
    },
    showCodeVariant() {
      return this.showCode ? 'confirm' : 'default';
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
            this.updateWidgetWithGridStackItem(item);
          });
        });
        this.grid.on('added', (event, items) => {
          items.forEach((item) => {
            this.updateWidgetWithGridStackItem(item);
          });
        });
      }
    },
    getGridAttribute(widget, attribute) {
      const { gridAttributes = {} } = widget;

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
    updateWidgetWithGridStackItem(item) {
      const updatedWidget = this.dashboard.widgets.find(
        (element) => element.id === Number(item.id),
      );
      if (updatedWidget) {
        updatedWidget.gridAttributes = this.convertToGridAttributes(item);
      }
      const selectedDefaultWidget = this.dashboard.default.widgets.find(
        (element) => element.id === Number(item.id),
      );
      if (selectedDefaultWidget) {
        selectedDefaultWidget.gridAttributes = this.convertToGridAttributes(item);
      }
    },
    handleWidgetError(widgetTitle, error) {
      createAlert({
        message: sprintf(
          s__('ProductAnalytics|An error occured while loading the %{widgetTitle} widget.'),
          { widgetTitle },
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
    <div class="grid-stack-container gl-display-flex gl-bg-gray-10">
      <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-py-6">
        <div v-if="!showCode" class="grid-stack">
          <div
            v-for="(widget, index) in dashboard.widgets"
            :id="'widget-' + widget.id"
            :key="index"
            :gs-id="widget.id"
            :gs-x="getGridAttribute(widget, 'xPos')"
            :gs-y="getGridAttribute(widget, 'yPos')"
            :gs-h="getGridAttribute(widget, 'height')"
            :gs-w="getGridAttribute(widget, 'width')"
            :gs-min-h="getGridAttribute(widget, 'minHeight')"
            :gs-min-w="getGridAttribute(widget, 'minWidth')"
            :gs-max-h="getGridAttribute(widget, 'maxHeight')"
            :gs-max-w="getGridAttribute(widget, 'maxWidth')"
            class="grid-stack-item"
            data-testid="grid-stack-widget"
          >
            <widgets-base
              :title="widget.title"
              :visualization="widget.visualization"
              :query-overrides="widget.queryOverrides"
              @error="handleWidgetError(widget.title, $event)"
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
</template>
