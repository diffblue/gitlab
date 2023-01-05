import { nextTick } from 'vue';
import { GlLabel } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AnalyticsMeasureSelector from 'ee/product_analytics/dashboards/components/widget_designer/analytics_cube_query_measure_selector.vue';
import { EVENTS_DB_TABLE_NAME } from 'ee/product_analytics/dashboards/constants';

describe('AnalyticsQueryMeasureSelector', () => {
  let wrapper;

  const findMeasureSummary = () => wrapper.findByTestId('measure-summary');
  const findBackButton = () => wrapper.findByTestId('measure-back-button');

  const setMeasures = jest.fn();
  const setFilters = jest.fn();
  const addFilters = jest.fn();

  const createWrapper = () => {
    wrapper = shallowMountExtended(AnalyticsMeasureSelector, {
      propsData: {
        measures: [],
        setMeasures,
        filters: [],
        setFilters,
        addFilters,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should not render back button on overview', () => {
      expect(findBackButton().exists()).toBe(false);
    });

    it('backbutton fires a setMeasure correctly', async () => {
      const overvViewButton = wrapper.findByTestId('pageviews-button');

      overvViewButton.vm.$emit('click');

      await nextTick();

      findBackButton().vm.$emit('click');

      expect(setMeasures).toHaveBeenCalledWith([]);
      expect(setFilters).toHaveBeenCalledWith([]);
    });
  });

  it.each`
    startbutton             | showAllbutton               | selectMethod       | summaryString
    ${'pageviews-button'}   | ${'pageviews-all-button'}   | ${'pageViews'}     | ${'pageViews::all'}
    ${'feature-button'}     | ${'feature-all-button'}     | ${'featureUsages'} | ${'featureUsages::all'}
    ${'clickevents-button'} | ${'clickevents-all-button'} | ${'clickEvents'}   | ${'clickEvents::all'}
    ${'events-button'}      | ${'events-all-button'}      | ${'events'}        | ${'events::all'}
  `(
    'navigates from overview to subpage $selectMethod',
    async ({ startbutton, showAllbutton, selectMethod, summaryString }) => {
      createWrapper();

      const overvViewButton = wrapper.findByTestId(startbutton);
      const summarySubValues = summaryString.split('::');

      // Overview
      overvViewButton.vm.$emit('click');

      await nextTick();

      // Detail selection checks
      expect(wrapper.findByTestId(startbutton).exists()).toBe(false);

      const showAllEventsButton = wrapper.findByTestId(showAllbutton);
      expect(showAllEventsButton.exists()).toBe(true);
      expect(findBackButton().exists()).toBe(true);

      showAllEventsButton.vm.$emit('click');

      expect(wrapper.emitted('measureSelected')).toEqual([[summarySubValues[0]], summarySubValues]);

      await nextTick();

      expect(wrapper.vm.measureType).toBe(selectMethod);
      expect(wrapper.vm.measureSubType).toBe('all');

      expect(setMeasures).toHaveBeenCalledWith([`${EVENTS_DB_TABLE_NAME}.count`]);
      if (summarySubValues[0] === 'pageViews') {
        expect(addFilters).toHaveBeenCalledWith({
          member: `${EVENTS_DB_TABLE_NAME}.eventType`,
          operator: 'equals',
          values: ['pageview'],
        });
      }

      expect(findMeasureSummary().exists()).toBe(true);
      expect(wrapper.findComponent(GlLabel).props('title')).toContain(summaryString);
    },
  );
});
