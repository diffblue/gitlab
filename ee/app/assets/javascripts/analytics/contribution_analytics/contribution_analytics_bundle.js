import { sortBy } from 'lodash';
import Vue from 'vue';
import { __ } from '~/locale';
import ColumnChart from './components/column_chart.vue';

const sortByValue = (data) => sortBy(data, (item) => item[1]).reverse();

const allValuesEmpty = (graphData) =>
  graphData.reduce((acc, data) => acc + Math.min(0, data[1]), 0) === 0;

export default (dataEl) => {
  if (!dataEl) return;

  const data = JSON.parse(dataEl.innerHTML);
  const outputElIds = ['push', 'issues_closed', 'merge_requests_created'];

  const xAxisType = 'category';
  const xAxisTitle = __('User');

  const formattedData = {
    push: [],
    issues_closed: [],
    merge_requests_created: [],
  };

  outputElIds.forEach((id) => {
    data[id].data.forEach((d, index) => {
      formattedData[id].push([data.labels[index], d]);
    });
  });

  const pushesEl = document.getElementById('js_pushes_chart_vue');
  if (allValuesEmpty(formattedData.push)) {
    // eslint-disable-next-line no-new
    new Vue({
      el: pushesEl,
      components: {
        ColumnChart,
      },
      render(h) {
        return h(ColumnChart, {
          props: {
            chartData: sortByValue(formattedData.push),
            xAxisTitle,
            yAxisTitle: __('Pushes'),
            xAxisType,
          },
        });
      },
    });
  }

  const mergeRequestEl = document.getElementById('js_merge_requests_chart_vue');
  if (allValuesEmpty(formattedData.merge_requests_created)) {
    // eslint-disable-next-line no-new
    new Vue({
      el: mergeRequestEl,
      components: {
        ColumnChart,
      },
      render(h) {
        return h(ColumnChart, {
          props: {
            chartData: sortByValue(formattedData.merge_requests_created),
            xAxisTitle,
            yAxisTitle: __('Merge Requests created'),
            xAxisType,
          },
        });
      },
    });
  }

  const issueEl = document.getElementById('js_issues_chart_vue');
  if (allValuesEmpty(formattedData.issues_closed)) {
    // eslint-disable-next-line no-new
    new Vue({
      el: issueEl,
      components: {
        ColumnChart,
      },
      render(h) {
        return h(ColumnChart, {
          props: {
            chartData: sortByValue(formattedData.issues_closed),
            xAxisTitle,
            yAxisTitle: __('Issues closed'),
            xAxisType,
          },
        });
      },
    });
  }
};
