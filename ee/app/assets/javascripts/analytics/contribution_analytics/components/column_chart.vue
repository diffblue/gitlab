<script>
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { getDataZoomOption } from '~/analytics/shared/utils';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import { truncateWidth } from '~/lib/utils/text_utility';

import {
  CHART_HEIGHT,
  CHART_X_AXIS_NAME_TOP_PADDING,
  CHART_X_AXIS_ROTATE,
  INNER_CHART_HEIGHT,
} from '../constants';

export default {
  components: {
    GlColumnChart,
  },
  props: {
    chartData: {
      type: Array,
      required: true,
    },
    xAxisTitle: {
      type: String,
      required: false,
      default: '',
    },
    yAxisTitle: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      width: 0,
      height: CHART_HEIGHT,
      svgs: {},
    };
  },
  computed: {
    handleIcon() {
      return this.svgs['scroll-handle'] ? { handleIcon: this.svgs['scroll-handle'] } : {};
    },
    dataZoomOption() {
      const dataZoom = [
        {
          type: 'slider',
          bottom: 10,
          start: 0,
          ...this.handleIcon,
        },
      ];

      return {
        dataZoom: getDataZoomOption({ totalItems: this.chartData.length, dataZoom }),
      };
    },
    chartOptions() {
      return {
        ...this.dataZoomOption,
        height: INNER_CHART_HEIGHT,
        xAxis: {
          axisLabel: {
            rotate: CHART_X_AXIS_ROTATE,
            formatter(value) {
              return truncateWidth(value);
            },
          },
          nameTextStyle: {
            padding: [CHART_X_AXIS_NAME_TOP_PADDING, 0, 0, 0],
          },
        },
      };
    },
    seriesData() {
      return [{ name: 'full', data: this.chartData }];
    },
  },
  methods: {
    setSvg(name) {
      return getSvgIconPathContent(name)
        .then((path) => {
          if (path) {
            this.$set(this.svgs, name, `path://${path}`);
          }
        })
        .catch((e) => {
          // eslint-disable-next-line no-console, @gitlab/require-i18n-strings
          console.error('SVG could not be rendered correctly: ', e);
        });
    },
    onChartCreated(columnChart) {
      this.setSvg('scroll-handle');
      columnChart.on('datazoom', this.updateAxisNamePadding);
    },
  },
};
</script>

<template>
  <gl-column-chart
    ref="columnChart"
    v-bind="$attrs"
    :width="width"
    :height="height"
    :bars="seriesData"
    :responsive="true"
    :x-axis-title="xAxisTitle"
    :y-axis-title="yAxisTitle"
    x-axis-type="category"
    :option="chartOptions"
    @created="onChartCreated"
  />
</template>
