import { GlEmptyState } from '@gitlab/ui';
import IssuesAnalyticsEmptyState from 'ee/issues_analytics/components/issues_analytics_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('IssuesAnalyticsEmptyState', () => {
  let wrapper;

  const svgHeight = 150;
  const mockNoDataSvgPath = 'no-data.svg';
  const mockNoDataWithFiltersSvgPath = 'no-data-with-filters.svg';
  const mockNoDataEmptyState = {
    title: 'Get started with issue analytics',
    description: 'Create issues for projects in your group to track and see metrics for them.',
    svgPath: mockNoDataSvgPath,
    svgHeight,
  };
  const mockNoDataWithFiltersEmptyState = {
    title: 'Sorry, your filter produced no results',
    description: 'To widen your search, change or remove filters in the filter bar above.',
    svgPath: mockNoDataWithFiltersSvgPath,
    svgHeight,
  };
  const defaultProvide = {
    noDataEmptyStateSvgPath: mockNoDataSvgPath,
    filtersEmptyStateSvgPath: mockNoDataWithFiltersSvgPath,
  };

  const createComponent = ({ props = {}, provide = defaultProvide } = {}) => {
    wrapper = shallowMountExtended(IssuesAnalyticsEmptyState, {
      propsData: {
        ...props,
      },
      provide,
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  describe.each`
    description               | emptyStateType         | expectedEmptyStateProps
    ${'No data'}              | ${'noData'}            | ${mockNoDataEmptyState}
    ${'No data with filters'} | ${'noDataWithFilters'} | ${mockNoDataWithFiltersEmptyState}
  `('$description empty state', ({ emptyStateType, expectedEmptyStateProps }) => {
    beforeEach(() => {
      createComponent({ props: { emptyStateType } });
    });

    it('should render the correct empty state type', () => {
      expect(findEmptyState().props()).toMatchObject(expectedEmptyStateProps);
    });
  });
});
