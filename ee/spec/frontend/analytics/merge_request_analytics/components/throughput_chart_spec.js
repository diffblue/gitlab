import { GlAlert } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ThroughputChart from 'ee/analytics/merge_request_analytics/components/throughput_chart.vue';
import ThroughputStats from 'ee/analytics/merge_request_analytics/components/throughput_stats.vue';
import throughputChartQueryBuilder from 'ee/analytics/merge_request_analytics/graphql/throughput_chart_query_builder';
import { THROUGHPUT_CHART_STRINGS } from 'ee/analytics/merge_request_analytics/constants';
import store from 'ee/analytics/merge_request_analytics/store';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import {
  throughputChartData,
  throughputChartNoData,
  startDate,
  endDate,
  fullPath,
} from '../mock_data';

Vue.use(Vuex);
Vue.use(VueApollo);

const defaultQueryResolver = jest.fn().mockResolvedValue({ data: { throughputChartData: [] } });
const defaultQueryVariables = {
  assigneeUsername: null,
  authorUsername: null,
  milestoneTitle: null,
  labels: null,
};

describe('ThroughputChart', () => {
  let wrapper;

  function displaysComponent(component, visible) {
    const element = wrapper.findComponent(component);

    expect(element.exists()).toBe(visible);
  }

  function createWrapper({ queryResolver = null } = {}) {
    const query = throughputChartQueryBuilder(startDate, endDate);
    const apolloProvider = createMockApollo([[query, queryResolver || defaultQueryResolver]]);

    wrapper = shallowMount(ThroughputChart, {
      store,
      apolloProvider,
      provide: {
        fullPath,
      },
      propsData: {
        startDate,
        endDate,
      },
    });
  }

  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('default state', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('displays the throughput stats component', () => {
      expect(wrapper.findComponent(ThroughputStats).exists()).toBe(true);
    });

    it('displays the chart title', () => {
      const chartTitle = wrapper.find('[data-testid="chartTitle"').text();

      expect(chartTitle).toBe(THROUGHPUT_CHART_STRINGS.CHART_TITLE);
    });

    it('displays the chart description', () => {
      const chartDescription = wrapper.find('[data-testid="chartDescription"').text();

      expect(chartDescription).toBe(THROUGHPUT_CHART_STRINGS.CHART_DESCRIPTION);
    });

    it('displays an empty state message when there is no data', () => {
      const alert = findAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(THROUGHPUT_CHART_STRINGS.NO_DATA);
    });

    it('does not display a skeleton loader', () => {
      displaysComponent(ChartSkeletonLoader, false);
    });

    it('does not display the chart', () => {
      displaysComponent(GlAreaChart, false);
    });
  });

  describe('while loading', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays a skeleton loader', () => {
      displaysComponent(ChartSkeletonLoader, true);
    });

    it('does not display the chart', () => {
      displaysComponent(GlAreaChart, false);
    });

    it('does not display a no data message', () => {
      displaysComponent(GlAlert, false);
    });
  });

  describe('with data', () => {
    beforeEach(async () => {
      const queryResolver = jest.fn().mockResolvedValue({ data: { throughputChartData } });
      createWrapper({ queryResolver });
      await waitForPromises();
    });

    it('displays the chart', () => {
      displaysComponent(GlAreaChart, true);
    });

    it('does not display the skeleton loader', () => {
      displaysComponent(ChartSkeletonLoader, false);
    });

    it('does not display a no data message', () => {
      displaysComponent(GlAlert, false);
    });
  });

  describe('with no data in the response', () => {
    beforeEach(async () => {
      const queryResolver = jest
        .fn()
        .mockResolvedValue({ data: { throughputChartData: throughputChartNoData } });
      createWrapper({ queryResolver });
      await waitForPromises();
    });

    it('does not display a skeleton loader', () => {
      displaysComponent(ChartSkeletonLoader, false);
    });

    it('does not display the chart', () => {
      displaysComponent(GlAreaChart, false);
    });

    it('displays an empty state message when there is no data', () => {
      const alert = findAlert();

      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(THROUGHPUT_CHART_STRINGS.NO_DATA);
    });
  });

  describe('with errors', () => {
    beforeEach(async () => {
      const queryResolver = jest.fn().mockRejectedValue();
      createWrapper({ queryResolver });
      await waitForPromises();
    });

    it('does not display the chart', () => {
      displaysComponent(GlAreaChart, false);
    });

    it('does not display the skeleton loader', () => {
      displaysComponent(ChartSkeletonLoader, false);
    });

    it('displays an error message', () => {
      const alert = findAlert();

      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(THROUGHPUT_CHART_STRINGS.ERROR_FETCHING_DATA);
    });
  });

  describe('when fetching data', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('has initial variables set', () => {
      expect(
        wrapper.vm.$options.apollo.throughputChartData.variables.bind(wrapper.vm)(),
      ).toMatchObject(defaultQueryVariables);
    });

    it('gets filter variables from store', async () => {
      const operator = '=';
      const assigneeUsername = 'foo';
      const authorUsername = 'bar';
      const milestoneTitle = 'baz';
      const labels = ['quis', 'quux'];

      wrapper.vm.$store.dispatch('filters/initialize', {
        selectedAssignee: { value: assigneeUsername, operator },
        selectedAuthor: { value: authorUsername, operator },
        selectedMilestone: { value: milestoneTitle, operator },
        selectedLabelList: [
          { value: labels[0], operator },
          { value: labels[1], operator },
        ],
      });
      await nextTick();
      expect(
        wrapper.vm.$options.apollo.throughputChartData.variables.bind(wrapper.vm)(),
      ).toMatchObject({
        assigneeUsername,
        authorUsername,
        milestoneTitle,
        labels,
      });
    });
  });
});
