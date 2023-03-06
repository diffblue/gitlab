<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import projectsHistoryQuery from 'ee/security_dashboard/graphql/queries/project_vulnerabilities_by_day_and_count.query.graphql';
import SecurityTrainingPromoBanner from 'ee/security_dashboard/components/project/security_training_promo_banner.vue';
import { PROJECT_LOADING_ERROR_MESSAGE } from 'ee/security_dashboard/helpers';
import { createAlert } from '~/alert';
import { formatDate, getDateInPast } from '~/lib/utils/datetime_utility';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import { s__, __ } from '~/locale';

const CHART_DEFAULT_DAYS = 30;
const MAX_DAYS = 100;
const ISO_DATE = 'isoDate';
const SEVERITIES = [
  { key: 'critical', name: s__('severity|Critical'), color: '#660e00' },
  { key: 'high', name: s__('severity|High'), color: '#ae1800' },
  { key: 'medium', name: s__('severity|Medium'), color: '#9e5400' },
  { key: 'low', name: s__('severity|Low'), color: '#c17d10' },
  { key: 'unknown', name: s__('severity|Unknown'), color: '#868686' },
  { key: 'info', name: s__('severity|Info'), color: '#428fdc' },
];

export default {
  components: {
    SecurityTrainingPromoBanner,
    GlLoadingIcon,
    GlLineChart,
  },
  props: {
    projectFullPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  apollo: {
    trendsByDay: {
      query: projectsHistoryQuery,
      variables() {
        return {
          fullPath: this.projectFullPath,
          endDate: this.endDate,
          startDate: this.startDate,
        };
      },
      update({ project }) {
        return project.vulnerabilitiesCountByDay.nodes;
      },
      error() {
        createAlert({ message: PROJECT_LOADING_ERROR_MESSAGE });
      },
    },
  },
  data() {
    return {
      chartWidth: 0,
      trendsByDay: [],
      svgs: {},
    };
  },
  computed: {
    chartStartDate() {
      return formatDate(getDateInPast(new Date(), CHART_DEFAULT_DAYS), ISO_DATE);
    },
    startDate() {
      return formatDate(getDateInPast(new Date(), MAX_DAYS), ISO_DATE);
    },
    endDate() {
      return formatDate(new Date(), ISO_DATE);
    },
    dataSeries() {
      const series = SEVERITIES.map(({ key, name, color }) => ({
        key,
        name,
        data: [],
        itemStyle: {
          color,
        },
        lineStyle: {
          color,
        },
      }));

      this.trendsByDay.forEach((trend) => {
        const { date, ...severities } = trend;

        SEVERITIES.forEach(({ key }) => {
          series.find((s) => s.key === key).data.push([date, severities[key]]);
        });
      });

      return series;
    },
    isLoadingTrends() {
      return this.$apollo.queries.trendsByDay.loading;
    },
    chartOptions() {
      return {
        xAxis: {
          name: __('Time'),
          key: 'time',
          type: 'category',
        },
        yAxis: {
          name: __('Vulnerabilities'),
          key: 'vulnerabilities',
          type: 'value',
          minInterval: 1,
        },
        dataZoom: [
          {
            type: 'slider',
            startValue: this.chartStartDate,
            handleIcon: this.svgs['scroll-handle'],
          },
        ],
        toolbox: {
          feature: {
            dataZoom: {
              icon: { zoom: this.svgs['marquee-selection'], back: this.svgs.redo },
            },
            restore: {
              icon: this.svgs.repeat,
            },
            saveAsImage: {
              icon: this.svgs.download,
            },
          },
        },
      };
    },
  },
  created() {
    ['marquee-selection', 'redo', 'repeat', 'download', 'scroll-handle'].forEach(this.setSvg);
  },
  methods: {
    async setSvg(name) {
      try {
        this.$set(this.svgs, name, `path://${await getSvgIconPathContent(name)}`);
      } catch (e) {
        // eslint-disable-next-line no-console, @gitlab/require-i18n-strings
        console.error('SVG could not be rendered correctly: ', e);
      }
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoadingTrends" size="lg" class="gl-mt-6" />

  <div v-else>
    <security-training-promo-banner />
    <gl-line-chart
      class="gl-mt-6"
      :data="dataSeries"
      :option="chartOptions"
      responsive
      :include-legend-avg-max="false"
    />
  </div>
</template>
