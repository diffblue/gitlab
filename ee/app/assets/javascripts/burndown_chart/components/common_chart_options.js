import dateFormat from '~/lib/dateformat';

const msInOneDay = 60 * 60 * 24 * 1000;

export default {
  grid: {
    // TODO: containLabel doesn't currently work, so we also need to add grid
    // https://github.com/apache/incubator-echarts/issues/11773
    containLabel: true,
    top: 16,
    bottom: 16,
    left: 48,
    right: 48,
  },
  xAxis: {
    name: '',
    type: 'time',
    minInterval: msInOneDay,
    axisLabel: {
      formatter(value) {
        return dateFormat(value, 'dd mmm yyyy');
      },
    },
    axisLine: {
      show: true,
    },
    axisPointer: {
      snap: true,
    },
  },
  yAxis: {
    axisLine: {
      show: true,
    },
    splitLine: {
      show: false,
    },
    minInterval: 1,
  },
  tooltip: {
    trigger: 'item',
    formatter: () => '',
  },
};
