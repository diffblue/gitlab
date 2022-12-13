<script>
import { GridStack } from 'gridstack';
import * as Sentry from '@sentry/browser';
import { loadCSSFile } from '~/lib/utils/css_utils';
import { createAlert } from '~/flash';
import { s__, sprintf } from '~/locale';
import WidgetsBase from './widgets_base.vue';
import { GRIDSTACK_MARGIN, GRIDSTACK_CSS_HANDLE } from './constants';

export default {
  name: 'CustomizableDashboard',
  components: {
    WidgetsBase,
  },
  props: {
    editable: {
      type: Boolean,
      required: false,
      default: false,
    },
    widgets: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      cssLoaded: false,
      mounted: true,
    };
  },
  computed: {
    loaded() {
      return this.cssLoaded && this.mounted;
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
  },
  unmounted() {
    this.mounted = false;
  },
  methods: {
    initGridStack() {
      if (this.loaded) {
        GridStack.init({
          staticGrid: !this.editable,
          margin: GRIDSTACK_MARGIN,
          handle: GRIDSTACK_CSS_HANDLE,
        });
      }
    },
    getGridAttribute(widget, attribute) {
      const { gridAttributes = {} } = widget;

      return gridAttributes[attribute];
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
  <div class="grid-stack-container gl-py-6">
    <div class="grid-stack">
      <div
        v-for="(widget, index) in widgets"
        :key="index"
        :gs-id="index"
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
  </div>
</template>
