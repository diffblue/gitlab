import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import BurnupQueryIteration from 'shared_queries/burndown_chart/burnup.iteration.query.graphql';
import BurnupQueryMilestone from 'shared_queries/burndown_chart/burnup.milestone.query.graphql';
import BurnCharts from 'ee/burndown_chart/components/burn_charts.vue';
import BurndownChart from 'ee/burndown_chart/components/burndown_chart.vue';
import BurnupChart from 'ee/burndown_chart/components/burnup_chart.vue';
import OpenTimeboxSummary from 'ee/burndown_chart/components/open_timebox_summary.vue';
import TimeboxSummaryCards from 'ee/burndown_chart/components/timebox_summary_cards.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useFakeDate } from 'helpers/fake_date';
import waitForPromises from 'helpers/wait_for_promises';
import { day1, day2, day3, day4 } from '../mock_data';

function useFakeDateFromDay({ date }) {
  const [year, month, day] = date.split('-');

  useFakeDate(year, month - 1, day);
}

describe('burndown_chart', () => {
  let wrapper;
  let mock;

  const findFilterLabel = () => wrapper.findComponent({ ref: 'filterLabel' });
  const findIssuesButton = () => wrapper.findComponent({ ref: 'totalIssuesButton' });
  const findWeightButton = () => wrapper.findComponent({ ref: 'totalWeightButton' });
  const findActiveButtons = () =>
    wrapper
      .findAllComponents(GlButton)
      .filter((button) => button.attributes().category === 'primary');
  const findBurndownChart = () => wrapper.findComponent(BurndownChart);
  const findBurnupChart = () => wrapper.findComponent(BurnupChart);
  const findOldBurndownChartButton = () => wrapper.findComponent({ ref: 'oldBurndown' });
  const findNewBurndownChartButton = () => wrapper.findComponent({ ref: 'newBurndown' });

  const defaultProps = {
    fullPath: 'gitlab-org/subgroup',
    startDate: '2020-08-07',
    dueDate: '2020-09-09',
    openIssuesCount: [],
    openIssuesWeight: [],
    burndownEventsPath: '/api/v4/projects/1234/milestones/1/burndown_events',
  };

  const createComponent = ({ props = {}, data = {}, loading = false } = {}) => {
    wrapper = shallowMount(BurnCharts, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      mocks: {
        $apollo: {
          queries: {
            report: {
              loading,
            },
          },
        },
      },
      data() {
        return data;
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  it('passes loading=true through to charts', () => {
    createComponent({ loading: true });

    expect(findBurndownChart().props('loading')).toBe(true);
    expect(findBurnupChart().props('loading')).toBe(true);
  });

  it('passes loading=false through to charts', () => {
    createComponent({ loading: false });

    expect(findBurndownChart().props('loading')).toBe(false);
    expect(findBurnupChart().props('loading')).toBe(false);
  });

  it('includes Issues and Issue weight buttons', () => {
    createComponent();

    expect(findIssuesButton().text()).toBe('Issues');
    expect(findWeightButton().text()).toBe('Issue weight');
  });

  it('defaults to total issues', () => {
    createComponent();

    expect(findActiveButtons()).toHaveLength(1);
    expect(findActiveButtons().at(0).text()).toBe('Issues');
    expect(findBurndownChart().props('issuesSelected')).toBe(true);
  });

  it('toggles Issue weight', async () => {
    createComponent();

    findWeightButton().vm.$emit('click');

    await nextTick();

    expect(findActiveButtons()).toHaveLength(1);
    expect(findActiveButtons().at(0).text()).toBe('Issue weight');
    expect(findBurndownChart().props('issuesSelected')).toBe(false);
  });

  it('reduces width of burndown chart', () => {
    createComponent();

    expect(findBurndownChart().classes()).toContain('col-md-6');
  });

  it('sets section title and chart title correctly', () => {
    createComponent();

    expect(findFilterLabel().text()).toBe('Filter by');
    expect(findBurndownChart().props().showTitle).toBe(true);
  });

  it('sets weight prop of burnup chart', async () => {
    createComponent();

    findWeightButton().vm.$emit('click');

    await nextTick();

    expect(findBurnupChart().props('issuesSelected')).toBe(false);
  });

  it('renders IterationReportSummaryOpen for open iteration', () => {
    createComponent({
      data: {
        report: {
          stats: {},
        },
      },
      props: {
        iterationState: 'open',
        iterationId: 'gid://gitlab/Iteration/11',
      },
    });

    expect(wrapper.findComponent(OpenTimeboxSummary).props()).toEqual({
      iterationId: 'gid://gitlab/Iteration/11',
      displayValue: 'count',
      namespaceType: 'group',
      fullPath: defaultProps.fullPath,
    });
  });

  it('renders TimeboxSummaryCards for closed iterations', () => {
    createComponent({
      data: {
        report: {
          stats: {},
        },
      },
      props: {
        iterationState: 'closed',
        iterationId: 'gid://gitlab/Iteration/1',
      },
    });

    expect(wrapper.findComponent(TimeboxSummaryCards).exists()).toBe(true);
  });

  it('uses burndown data computed from burnup data', () => {
    createComponent({
      data: {
        report: {
          burnupData: [day1],
        },
      },
    });
    const { openIssuesCount, openIssuesWeight } = findBurndownChart().props();

    const expectedCount = [day1.date, day1.scopeCount - day1.completedCount];
    const expectedWeight = [day1.date, day1.scopeWeight - day1.completedWeight];

    expect(openIssuesCount).toEqual([expectedCount]);
    expect(openIssuesWeight).toEqual([expectedWeight]);
  });

  describe('showNewOldBurndownToggle', () => {
    it('hides old/new burndown buttons if props is false', () => {
      createComponent({ props: { showNewOldBurndownToggle: false } });

      expect(findOldBurndownChartButton().exists()).toBe(false);
      expect(findNewBurndownChartButton().exists()).toBe(false);
    });

    it('shows old/new burndown buttons if prop true', () => {
      createComponent({ props: { showNewOldBurndownToggle: true } });

      expect(findOldBurndownChartButton().exists()).toBe(true);
      expect(findNewBurndownChartButton().exists()).toBe(true);
    });

    it('calls fetchLegacyBurndownEvents, but only once', () => {
      createComponent({ props: { showNewOldBurndownToggle: true } });
      jest.spyOn(wrapper.vm, 'fetchLegacyBurndownEvents');
      mock.onGet(defaultProps.burndownEventsPath).reply(HTTP_STATUS_OK, []);

      findOldBurndownChartButton().vm.$emit('click');

      expect(wrapper.vm.fetchLegacyBurndownEvents).toHaveBeenCalledTimes(1);
    });
  });

  // some separate tests for the update function since it has a bunch of logic
  describe('padSparseBurnupData function', () => {
    useFakeDateFromDay(day4);

    beforeEach(() => {
      createComponent({
        props: { startDate: day1.date, dueDate: day4.date },
      });
    });

    it('pads data from startDate if no startDate values', () => {
      const result = wrapper.vm.padSparseBurnupData([day2, day3, day4]);

      expect(result.length).toBe(4);
      expect(result[0]).toEqual({
        date: day1.date,
        completedCount: 0,
        completedWeight: 0,
        scopeCount: 0,
        scopeWeight: 0,
      });
    });

    it('if dueDate is in the past, pad data using last existing value', () => {
      const result = wrapper.vm.padSparseBurnupData([day1, day2]);

      expect(result.length).toBe(4);
      expect(result[2]).toEqual({
        ...day2,
        date: day3.date,
      });
      expect(result[3]).toEqual({
        ...day2,
        date: day4.date,
      });
    });

    describe('when dueDate is in the future', () => {
      // day3 is before the day4 we set to dueDate in the beforeEach
      useFakeDateFromDay(day3);

      it('pad data up to current date using last existing value', () => {
        const result = wrapper.vm.padSparseBurnupData([day1, day2]);

        expect(result.length).toBe(3);
        expect(result[2]).toEqual({
          ...day2,
          date: day3.date,
        });
      });
    });

    it('pads missing days with data from previous days', () => {
      const result = wrapper.vm.padSparseBurnupData([day1, day4]);

      expect(result.length).toBe(4);
      expect(result[1]).toEqual({
        ...day1,
        date: day2.date,
      });
      expect(result[2]).toEqual({
        ...day1,
        date: day3.date,
      });
    });
  });

  describe('fullPath is only passed for iteration report', () => {
    let burnupQuerySpy;

    const createComponentWithApollo = ({ query, props = {} }) => {
      Vue.use(VueApollo);
      burnupQuerySpy = jest.fn();
      wrapper = shallowMount(BurnCharts, {
        apolloProvider: createMockApollo([[query, burnupQuerySpy]]),
        propsData: {
          ...defaultProps,
          ...props,
        },
      });
    };

    it('makes a request with a fullPath for iteration', async () => {
      createComponentWithApollo({ query: BurnupQueryIteration, props: { iterationId: 'id' } });
      await waitForPromises();

      expect(burnupQuerySpy).toHaveBeenCalledTimes(1);
      expect(burnupQuerySpy).toHaveBeenCalledWith(
        expect.objectContaining({
          iterationId: 'id',
          fullPath: defaultProps.fullPath,
        }),
      );
    });

    it('makes a request without a fullPath for milestone', async () => {
      createComponentWithApollo({ query: BurnupQueryMilestone, props: { milestoneId: 'id' } });
      await waitForPromises();

      expect(burnupQuerySpy).toHaveBeenCalledTimes(1);
      expect(burnupQuerySpy).toHaveBeenCalledWith(
        expect.objectContaining({
          milestoneId: 'id',
        }),
      );
      expect(burnupQuerySpy).toHaveBeenCalledWith(
        expect.not.objectContaining({
          fullPath: defaultProps.fullPath,
        }),
      );
    });
  });
});
