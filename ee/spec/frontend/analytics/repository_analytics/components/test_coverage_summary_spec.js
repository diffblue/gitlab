import { GlSkeletonLoader, GlSprintf } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import TestCoverageSummary from 'ee/analytics/repository_analytics/components/test_coverage_summary.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { nDaysBefore, formatDate } from '~/lib/utils/datetime_utility';

describe('Test coverage table component', () => {
  let wrapper;

  const findAllSingleStats = () => wrapper.findAllComponents(GlSingleStat);
  const findProjectsWithTests = () => findAllSingleStats().at(0);
  const findAverageCoverage = () => findAllSingleStats().at(1);
  const findTotalCoverages = () => findAllSingleStats().at(2);
  const findGroupCoverageChart = () => wrapper.findByTestId('group-coverage-chart');
  const findChartLoadingState = () => wrapper.findByTestId('group-coverage-chart-loading');
  const findChartEmptyState = () => wrapper.findByTestId('group-coverage-chart-empty');
  const findCoverageHeader = () => wrapper.findByTestId('test-coverage-header');
  const findLastUpdated = () => wrapper.findByTestId('test-coverage-last-updated');
  const findLoadingState = () => wrapper.findComponent(GlSkeletonLoader);

  const createComponent = ({ data = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(TestCoverageSummary, {
        data() {
          return {
            projectCount: null,
            averageCoverage: null,
            coverageCount: null,
            hasError: false,
            isLoading: false,
            ...data,
          };
        },
        mocks: {
          $apollo: {
            queries: {
              group: {
                query: jest.fn().mockResolvedValue(),
              },
            },
          },
        },
        stubs: {
          GlSingleStat,
          GlSprintf,
        },
      }),
    );
  };

  it('renders test coverage header', () => {
    createComponent();

    expect(findCoverageHeader().exists()).toBe(true);
  });

  describe('last updated date', () => {
    it.each([
      [null, 'Last updated'],
      [0, 'Last updated today'],
      [1, 'Last updated 1 day ago'],
      [730, 'Last updated 2 years ago'],
    ])('when last updated date is %p days ago, renders heading %p', (daysAgo, expectedText) => {
      const date =
        daysAgo === null
          ? null
          : formatDate(nDaysBefore(new Date(), daysAgo, { utc: true }), 'yyyy-mm-dd');

      createComponent({
        data: {
          groupCoverageChartData: [{ name: 'test', data: [[date, 79.6]] }],
          latestCoverageDate: date,
        },
      });

      expect(findLastUpdated().text()).toBe(expectedText);
    });
  });

  describe('when group code coverage is empty', () => {
    it('renders empty metrics', () => {
      createComponent();

      expect(findProjectsWithTests().text()).toContain('-');
      expect(findAverageCoverage().text()).toContain('-');
      expect(findTotalCoverages().text()).toContain('-');
    });

    it('renders empty chart state', () => {
      createComponent();

      expect(findChartEmptyState().exists()).toBe(true);
      expect(findGroupCoverageChart().exists()).toBe(false);
    });
  });

  describe('when query is loading', () => {
    it('renders loading state', () => {
      createComponent({ data: { isLoading: true } });

      expect(findLoadingState().exists()).toBe(true);
      expect(findChartLoadingState().exists()).toBe(true);
    });
  });

  describe('when group code coverage is available', () => {
    it('renders coverage metrics', () => {
      const projectCount = '5';
      const averageCoverage = '74.35';
      const coverageCount = '5';

      createComponent({
        data: {
          projectCount,
          averageCoverage,
          coverageCount,
        },
      });

      expect(findProjectsWithTests().props('value')).toBe(projectCount);
      expect(findAverageCoverage().props('value')).toBe(`${averageCoverage}`);
      expect(findAverageCoverage().props('unit')).toBe('%');
      expect(findTotalCoverages().props('value')).toBe(coverageCount);
    });

    it('renders area chart with correct data', () => {
      createComponent({
        data: {
          groupCoverageChartData: [
            {
              name: 'test',
              data: [
                ['2020-01-10', 77.9],
                ['2020-01-11', 78.7],
                ['2020-01-12', 79.6],
              ],
            },
          ],
        },
      });

      expect(findGroupCoverageChart().exists()).toBe(true);
      expect(findGroupCoverageChart().props('data')).toMatchSnapshot();
    });

    it('formats the area chart labels correctly', () => {
      createComponent({
        data: {
          groupCoverageChartData: [
            {
              name: 'test',
              data: [
                ['2020-01-10', 77.9],
                ['2020-01-11', 78.7],
                ['2020-01-12', 79.6],
              ],
            },
          ],
        },
      });

      expect(findGroupCoverageChart().props('option').xAxis.axisLabel.formatter('2020-01-10')).toBe(
        'Jan 10',
      );
      expect(findGroupCoverageChart().props('option').yAxis.axisLabel.formatter(80)).toBe('80%');
    });
  });
});
