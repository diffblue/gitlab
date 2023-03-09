import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import VulnerabilitiesOverTimeChart from 'ee/security_dashboard/components/shared/vulnerabilities_over_time_chart.vue';
import ChartButtons from 'ee/security_dashboard/components/shared/vulnerabilities_over_time_chart_buttons.vue';
import groupVulnerabilityHistoryQuery from 'ee/security_dashboard/graphql/queries/group_vulnerability_history.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

jest.mock('~/alert');
Vue.use(VueApollo);

const SecurityDashboardCard = {
  props: ['isLoading'],
  template: `
    <div>
      <p data-testid="timeInfo">
        <slot name="help-text" />
      </p>
      <slot name="controls" />
      <slot />
    </div>
  `,
};

describe('Vulnerabilities Over Time Chart Component', () => {
  let wrapper;

  const defaultRequestHandler = jest.fn().mockResolvedValue({
    data: {
      group: {
        id: 'group',
        vulnerabilitiesCountByDay: {
          nodes: [
            { date: '2020-05-18', critical: 5, high: 4, medium: 3, low: 2 },
            { date: '2020-05-19', critical: 6, high: 5, medium: 4, low: 3 },
            { date: '2020-05-20', critical: 7, high: 6, medium: 5, low: 4 },
          ],
        },
      },
    },
  });

  const findSecurityDashboardCard = () => wrapper.findComponent(SecurityDashboardCard);
  const findTimeInfo = () => wrapper.findByTestId('timeInfo');
  const findChartButtons = () => wrapper.findComponent(ChartButtons);

  const createComponent = ({ requestHandler = defaultRequestHandler } = {}) => {
    wrapper = shallowMountExtended(VulnerabilitiesOverTimeChart, {
      apolloProvider: createMockApollo([[groupVulnerabilityHistoryQuery, requestHandler]]),
      propsData: { query: groupVulnerabilityHistoryQuery },
      provide: { groupFullPath: 'group' },
      stubs: {
        SecurityDashboardCard,
      },
    });
  };

  describe('header', () => {
    it.each`
      dayRange | expectedStartDate
      ${90}    | ${'October 3rd'}
      ${60}    | ${'November 2nd'}
      ${30}    | ${'December 2nd'}
    `(
      'shows "$expectedStartDate" when the date range is set to "$dayRange" days',
      async ({ dayRange, expectedStartDate }) => {
        jest.spyOn(global.Date, 'now').mockReturnValue(new Date('2000-01-01T00:00:00Z'));
        createComponent();
        await waitForPromises();
        findChartButtons().vm.$emit('days-selected', dayRange);
        await waitForPromises();

        expect(findTimeInfo().text()).toContain(expectedStartDate);
      },
    );
  });

  describe('date range selectors', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('should contain the chart buttons', () => {
      expect(findChartButtons().props('days')).toEqual([30, 60, 90]);
    });

    it('should pass the selected days to the chart buttons', () => {
      expect(findChartButtons().props('activeDay')).toBe(wrapper.vm.selectedDayRange);
    });

    it('should fetch new data when the chart button is changed', async () => {
      defaultRequestHandler.mockClear();
      findChartButtons().vm.$emit('days-selected', 90);
      await waitForPromises();

      expect(defaultRequestHandler).toHaveBeenCalledTimes(1);
    });
  });

  describe('when the history chart is loaded', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it("sets the card's loading prop to `true`", () => {
      expect(findSecurityDashboardCard().props('isLoading')).toBe(false);
    });

    it('should process the data returned from GraphQL properly', () => {
      expect(wrapper.vm.vulnerabilitiesHistory).toEqual({
        critical: { '2020-05-18': 5, '2020-05-19': 6, '2020-05-20': 7 },
        high: { '2020-05-18': 4, '2020-05-19': 5, '2020-05-20': 6 },
        medium: { '2020-05-18': 3, '2020-05-19': 4, '2020-05-20': 5 },
        low: { '2020-05-18': 2, '2020-05-19': 3, '2020-05-20': 4 },
      });
    });
  });

  describe('vulnerabilities history query', () => {
    it("starts the query immediately and sets the card's loading prop to `true`", () => {
      createComponent();

      expect(defaultRequestHandler).toHaveBeenCalledTimes(1);
      expect(findSecurityDashboardCard().props('isLoading')).toBe(true);
    });

    it('will show an alert when there is a request error', async () => {
      const requestHandler = jest.fn().mockRejectedValue();
      createComponent({ requestHandler });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledTimes(1);
    });
  });
});
