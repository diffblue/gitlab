import { n__, s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { formattedChangeInPercent } from '~/lib/utils/number_utils';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';

export default {
  name: 'WidgetBrowserPerformance',
  props: ['browserPerformance'],
  i18n: {
    label: s__('ciReport|Browser Performance'),
    loading: s__('ciReport|Browser performance test metrics results are being parsed'),
  },
  computed: {
    summary() {
      const { improved, degraded, same } = this.collapsedData;
      const changesFound = improved.length + degraded.length + same.length;
      const text = sprintf(
        n__(
          'ciReport|Browser performance test metrics: %{strong_start}%{changesFound}%{strong_end} change',
          'ciReport|Browser performance test metrics: %{strong_start}%{changesFound}%{strong_end} changes',
          changesFound,
        ),
        {
          changesFound,
        },
        false,
      );

      const reportNumbersText = sprintf(
        s__(
          'ciReport|%{danger_start}%{degradedNum} degraded%{danger_end}, %{same_start}%{sameNum} same%{same_end}, and %{success_start}%{improvedNum} improved%{success_end}',
        ),
        {
          degradedNum: degraded.length,
          sameNum: same.length,
          improvedNum: improved.length,
        },
      );

      return {
        subject: text,
        meta: reportNumbersText,
      };
    },
    statusIcon() {
      if (this.collapsedData.degraded.length || this.collapsedData.same.length) {
        return EXTENSION_ICONS.warning;
      }
      return EXTENSION_ICONS.success;
    },
  },
  methods: {
    fetchCollapsedData() {
      const { head_path, base_path } = this.browserPerformance;

      return Promise.all([this.fetchReport(head_path), this.fetchReport(base_path)]).then(
        (values) => {
          return this.compareBrowserPerformanceMetrics(values[0], values[1]);
        },
      );
    },
    fetchFullData() {
      const { improved, degraded, same } = this.collapsedData;

      return Promise.resolve([...improved, ...degraded, ...same]);
    },
    compareBrowserPerformanceMetrics(headMetrics, baseMetrics) {
      const headMetricsIndexed = this.normalizeBrowserPerformanceMetrics(headMetrics);
      const baseMetricsIndexed = this.normalizeBrowserPerformanceMetrics(baseMetrics);
      const improved = [];
      const degraded = [];
      const same = [];

      Object.keys(headMetricsIndexed).forEach((subject) => {
        const subjectMetrics = headMetricsIndexed[subject];
        Object.keys(subjectMetrics).forEach((metric) => {
          const headMetricData = subjectMetrics[metric];

          if (baseMetricsIndexed[subject] && baseMetricsIndexed[subject][metric]) {
            const baseMetricData = baseMetricsIndexed[subject][metric];
            const metricData = {
              name: metric,
              path: subject,
              score: headMetricData.value,
              delta: headMetricData.value - baseMetricData.value,
            };

            if (metricData.delta !== 0) {
              const isImproved =
                headMetricData.desiredSize === 'smaller'
                  ? metricData.delta < 0
                  : metricData.delta > 0;

              if (isImproved) {
                improved.push(
                  this.prepareMetricData(metricData, {
                    name: EXTENSION_ICONS.success,
                  }),
                );
              } else {
                degraded.push(
                  this.prepareMetricData(metricData, {
                    name: EXTENSION_ICONS.failed,
                  }),
                );
              }
            } else {
              same.push(
                this.prepareMetricData(metricData, {
                  name: EXTENSION_ICONS.neutral,
                }),
              );
            }
          }
        });
      });

      return { improved, degraded, same };
    },
    prepareMetricData(metricData, icon) {
      const preparedMetricData = metricData;

      const prefix = metricData.score ? `${metricData.name}:` : metricData.name;
      const score = metricData.score ? `${this.formatScore(metricData.score)}` : '';
      const delta = metricData.delta ? `(${this.formatScore(metricData.delta)})` : '';
      const { path } = metricData;
      let deltaPercent = '';

      if (metricData.delta && metricData.score) {
        const oldScore = parseFloat(metricData.score) - metricData.delta;
        deltaPercent = `(${formattedChangeInPercent(oldScore, metricData.score)})`;
      }

      const text = sprintf(
        s__(
          'ciReport|%{prefix} %{strong_start}%{score}%{strong_end} %{delta} %{deltaPercent} in %{path}',
        ),
        {
          prefix,
          score,
          delta,
          deltaPercent,
          path,
        },
        false,
      );

      preparedMetricData.icon = icon;
      preparedMetricData.text = text;

      return preparedMetricData;
    },
    normalizeBrowserPerformanceMetrics(browserPerformanceData) {
      const indexedSubjects = {};
      browserPerformanceData.forEach(({ subject, metrics }) => {
        const indexedMetrics = {};
        metrics.forEach(({ name, ...data }) => {
          indexedMetrics[name] = data;
        });
        indexedSubjects[subject] = indexedMetrics;
      });

      return indexedSubjects;
    },
    formatScore(value) {
      if (Number(value) && !Number.isInteger(value)) {
        return (Math.floor(parseFloat(value) * 100) / 100).toFixed(2);
      }
      return value;
    },
    fetchReport(endpoint) {
      return axios.get(endpoint).then((res) => res.data);
    },
  },
};
