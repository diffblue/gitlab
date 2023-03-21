<script>
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { GlSkeletonLoader } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { s__, __ } from '~/locale';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { getToolboxOptions } from '~/lib/utils/chart_utils';
import { USAGE_BY_MONTH_HEADER } from '../../constants';

export default {
  i18n: {
    USAGE_BY_MONTH_HEADER,
    DATA_NAME: s__('UsageQuota|Transfer data used by month'),
    MONTH: s__('UsageQuota|Month'),
    USAGE: __('Usage'),
  },
  components: { GlAreaChart, GlSkeletonLoader },
  props: {
    chartData: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      tooltip: {},
      toolboxOptions: {},
    };
  },
  computed: {
    formattedData() {
      return [
        {
          name: this.$options.i18n.DATA_NAME,
          data: this.chartData,
        },
      ];
    },
    chartOption() {
      return {
        grid: {
          left: 80,
        },
        xAxis: {
          name: this.$options.i18n.MONTH,
          type: 'category',
        },
        yAxis: {
          name: this.$options.i18n.USAGE,
          nameGap: 65,
          axisLabel: {
            formatter(value) {
              return numberToHumanSize(value, 1);
            },
          },
        },
        ...this.toolboxOptions,
      };
    },
    shouldRenderSkeletonLoader() {
      return this.loading || isEmpty(this.toolboxOptions);
    },
  },
  async created() {
    this.toolboxOptions = await getToolboxOptions();
  },
  methods: {
    formatTooltipText({ seriesData }) {
      if (!seriesData?.[0]?.value) {
        return;
      }

      const [month, value] = seriesData[0].value;

      this.tooltip = {
        title: `${month} (${this.$options.i18n.MONTH})`,
        content: numberToHumanSize(value, 1),
      };
    },
  },
};
</script>

<template>
  <div class="gl-mt-5">
    <h4 class="gl-font-lg gl-m-0">{{ $options.i18n.USAGE_BY_MONTH_HEADER }}</h4>
    <div class="gl-w-full gl-mt-3">
      <div v-if="shouldRenderSkeletonLoader">
        <gl-skeleton-loader :height="335" :width="1248">
          <path
            d="M0 151.434L113.273 137.205L226.545 53L339.818 78.6823L453.091 117.295L566.364 213.921L679.636 85.7474L792.909 114.535L906.182 136.393L1019.45 170.153L1132.73 128.729L1246 102.981V335H1132.73H1019.45H906.182H792.909H679.636H566.364H453.091H339.818H226.545H113.273H0V151.434Z"
          />
        </gl-skeleton-loader>
      </div>
      <gl-area-chart
        v-else
        :data="formattedData"
        :option="chartOption"
        :format-tooltip-text="formatTooltipText"
        responsive
      >
        <template #tooltip-title> {{ tooltip.title }} </template>
        <template #tooltip-content> {{ tooltip.content }} </template>
      </gl-area-chart>
    </div>
  </div>
</template>
