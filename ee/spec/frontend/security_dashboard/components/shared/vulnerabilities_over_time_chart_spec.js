import { nextTick } from 'vue';
import { GlLoadingIcon, GlTable } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VulnerabilitiesOverTimeChart from 'ee/security_dashboard/components/shared/vulnerabilities_over_time_chart.vue';
import ChartButtons from 'ee/security_dashboard/components/shared/vulnerabilities_over_time_chart_buttons.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('Vulnerabilities Over Time Chart Component', () => {
  let wrapper;

  const responseData = {
    vulnerabilitiesCountByDay: {
      nodes: [
        { date: '2020-05-18', medium: 5 },
        { date: '2020-05-19', medium: 2 },
        { date: '2020-05-18', critical: 2 },
      ],
    },
  };

  const findTimeInfo = () => wrapper.findByTestId('timeInfo');
  const findChartButtons = () => wrapper.findComponent(ChartButtons);

  const mockApollo = (options) => {
    return {
      queries: {
        vulnerabilitiesHistory: { ...options },
      },
    };
  };

  const createComponent = ({ $apollo, propsData, stubs, data, provide } = {}) => {
    return extendedWrapper(
      shallowMount(VulnerabilitiesOverTimeChart, {
        propsData: { query: {}, ...propsData },
        provide: { groupFullPath: undefined, ...provide },
        mocks: { $apollo: mockApollo($apollo) },
        stubs,
        data,
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('header', () => {
    it.each`
      mockDate                  | dayRange | expectedStartDate
      ${'2000-01-01T00:00:00Z'} | ${90}    | ${'October 3rd'}
      ${'2000-01-01T00:00:00Z'} | ${60}    | ${'November 2nd'}
      ${'2000-01-01T00:00:00Z'} | ${30}    | ${'December 2nd'}
    `(
      'shows "$expectedStartDate" when the date range is set to "$dayRange" days',
      async ({ mockDate, dayRange, expectedStartDate }) => {
        jest.spyOn(global.Date, 'now').mockImplementation(() => new Date(mockDate));

        wrapper = createComponent({ data: () => ({ vulnerabilitiesHistoryDayRange: dayRange }) });

        await nextTick();
        expect(findTimeInfo().text()).toContain(expectedStartDate);
      },
    );
  });

  describe('date range selectors', () => {
    beforeEach(() => {
      wrapper = createComponent({
        $apollo: { refetch: jest.fn() },
      });
    });

    it('should contain the chart buttons', () => {
      expect(findChartButtons().props('days')).toEqual([30, 60, 90]);
    });

    it('should change the actively selected chart button and refetch the new data', async () => {
      const chartButtons = findChartButtons();

      expect(chartButtons.props('activeDay')).toBe(30);
      chartButtons.vm.$emit('days-selected', 90);

      await nextTick();

      expect(chartButtons.props('activeDay')).toBe(90);
      expect(wrapper.vm.$apollo.queries.vulnerabilitiesHistory.refetch).toHaveBeenCalledTimes(1);
    });
  });

  describe('when loading the history chart for group level dashboard', () => {
    beforeEach(() => {
      wrapper = createComponent({
        provide: { groupFullPath: 'gitlab-org' },
      });
    });

    it('should process the data returned from GraphQL properly', () => {
      expect(wrapper.vm.processRawData({ group: responseData })).toEqual({
        critical: { '2020-05-18': 2 },
        medium: { '2020-05-18': 5, '2020-05-19': 2 },
      });
    });
  });

  describe('when loading the history chart for instance level dashboard', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('should process the data returned from GraphQL properly', () => {
      expect(wrapper.vm.processRawData(responseData)).toEqual({
        critical: { '2020-05-18': 2 },
        medium: { '2020-05-18': 5, '2020-05-19': 2 },
      });
    });
  });

  describe('when query is loading', () => {
    beforeEach(() => {
      wrapper = createComponent({
        $apollo: { loading: true },
      });
    });

    it('only shows the header and loading icon', () => {
      expect(wrapper.find('h4').exists()).toBe(true);
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(findTimeInfo().exists()).toBe(false);
      expect(findChartButtons().exists()).toBe(false);
      expect(wrapper.findComponent(GlTable).exists()).toBe(false);
    });
  });
});
