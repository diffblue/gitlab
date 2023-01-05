import { nextTick } from 'vue';
import { GlLabel, GlDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AnalyticsDimensionSelector from 'ee/product_analytics/dashboards/components/widget_designer/analytics_cube_query_dimension_selector.vue';
import { EVENTS_DB_TABLE_NAME } from 'ee/product_analytics/dashboards/constants';

describe('AnalyticsQueryDimensionSelector', () => {
  let wrapper;

  const findDimensionSummary = () => wrapper.findByTestId('dimension-summary');
  const findBackButton = () => wrapper.findByTestId('dimension-back-button');
  const findDimensionLabel = () => wrapper.findComponent(GlLabel);

  const addDimensions = jest.fn();
  const removeDimension = jest.fn();
  const setTimeDimensions = jest.fn();
  const removeTimeDimension = jest.fn();

  const createWrapper = ({ selectedEventType = '', dimensions = [], timeDimensions = [] } = {}) => {
    wrapper = shallowMountExtended(AnalyticsDimensionSelector, {
      propsData: {
        dimensions,
        timeDimensions,
        measureType: selectedEventType,
        measureSubType: '',
        addDimensions,
        removeDimension,
        setTimeDimensions,
        removeTimeDimension,
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
  });

  const measuredSubTypes = [
    ['pages-url-button', 'url'],
    ['pages-docPath-button', 'docPath'],
    ['pages-pageTitle-button', 'pageTitle'],
    ['pages-docEncoding-button', 'docEncoding'],
    ['pages-docHost-button', 'docHost'],
    ['users-referer-button', 'referer'],
    ['users-userLanguage-button', 'userLanguage'],
    ['users-vpSize-button', 'vpSize'],
    ['users-parsedUaUaFamily-button', 'parsedUaUaFamily'],
    ['users-parsedUaOsFamily-button', 'parsedUaOsFamily'],
  ];

  const measuredSubTypesMultiValues = [
    ['users-parsedUaUaFamily-parsedUaUaVersion-button', ['parsedUaUaFamily', 'parsedUaUaVersion']],
    ['users-parsedUaOsFamily-parsedUaOsVersion-button', ['parsedUaOsFamily', 'parsedUaOsVersion']],
  ];

  describe('calls from overview', () => {
    it.each(measuredSubTypes)('to select %p', async (startbutton, selectMethod) => {
      createWrapper();

      const overvViewButton = wrapper.findByTestId(startbutton);

      // Overview
      expect(overvViewButton.exists()).toBe(true);
      overvViewButton.vm.$emit('click');

      await nextTick();

      expect(addDimensions).toHaveBeenCalledWith(`${EVENTS_DB_TABLE_NAME}.${selectMethod}`);
    });

    it.each(measuredSubTypesMultiValues)(
      'calls from overview for multi value types to select %p',
      async (startbutton, selectMethod) => {
        createWrapper();

        const overViewButton = wrapper.findByTestId(startbutton);

        // Overview
        expect(overViewButton.exists()).toBe(true);
        overViewButton.vm.$emit('click');

        await nextTick();

        // Detail selection checks
        expect(addDimensions).toHaveBeenCalledWith(`${EVENTS_DB_TABLE_NAME}.${selectMethod[0]}`);
        expect(addDimensions).toHaveBeenCalledWith(`${EVENTS_DB_TABLE_NAME}.${selectMethod[1]}`);
      },
    );
  });

  describe('Rendering Sub Page', () => {
    it.each(measuredSubTypes)('for %p', async (startbutton, selectMethod) => {
      createWrapper({
        dimensions: [
          {
            name: selectMethod,
            title: 'Test',
            type: 'string',
            shortTitle: selectMethod,
            suggestFilterValues: true,
            isVisible: true,
          },
        ],
      });

      wrapper.findByTestId(startbutton).vm.$emit('click');
      await nextTick();

      expect(wrapper.findByTestId(startbutton).exists()).toBe(false);

      expect(findDimensionSummary().exists()).toBe(true);
      expect(findDimensionLabel().props('title')).toContain(selectMethod);

      findDimensionLabel().vm.$emit('close', selectMethod);
      expect(removeDimension).toHaveBeenCalled();
    });

    it.each(measuredSubTypesMultiValues)('for %p', async (startbutton, selectMethod) => {
      createWrapper({
        dimensions: [
          {
            name: selectMethod,
            title: 'Test',
            type: 'string',
            shortTitle: selectMethod[0],
            suggestFilterValues: true,
            isVisible: true,
          },
        ],
      });

      wrapper.findByTestId(startbutton).vm.$emit('click');
      await nextTick();

      expect(wrapper.findByTestId(startbutton).exists()).toBe(false);

      expect(findDimensionSummary().exists()).toBe(true);
      expect(findDimensionLabel().props('title')).toContain(selectMethod[0]);

      findDimensionLabel().vm.$emit('close', selectMethod);
      expect(removeDimension).toHaveBeenCalled();
    });
  });

  describe('when timedimension is selected', () => {
    it('should setTimeDimensions when a granularity is selected', async () => {
      createWrapper();

      wrapper
        .findByTestId('event-granularities-dd')
        .findComponent(GlDropdownItem)
        .vm.$emit('click');

      expect(setTimeDimensions).toHaveBeenCalledWith([
        {
          dimension: `${EVENTS_DB_TABLE_NAME}.utcTime`,
          granularity: 'seconds',
        },
      ]);
    });

    it('should show currect granularity Label', async () => {
      createWrapper({
        timeDimensions: [
          {
            dimension: `${EVENTS_DB_TABLE_NAME}.utcTime`,
            granularity: 'seconds',
          },
        ],
      });

      wrapper
        .findByTestId('event-granularities-dd')
        .findComponent(GlDropdownItem)
        .vm.$emit('click');

      await nextTick();

      await findDimensionLabel().vm.$emit('close', 'seconds');

      expect(removeTimeDimension).toHaveBeenCalled();
    });
  });

  describe('when add another dimension button is clicked', () => {
    it('should render overview and select page', async () => {
      // Simulate the Dimension change that would happen by Cube Component
      createWrapper({
        dimensions: [
          {
            name: `${EVENTS_DB_TABLE_NAME}.url`,
            title: 'Test',
            type: 'string',
            shortTitle: `${EVENTS_DB_TABLE_NAME}.url`,
            suggestFilterValues: true,
            isVisible: true,
          },
        ],
      });
      wrapper.findByTestId('pages-url-button').vm.$emit('click');
      await nextTick();

      await wrapper.findByTestId('another-dimension-button').vm.$emit('click');

      expect(wrapper.findByTestId('pages-url-button').exists()).toBe(true);
      expect(findDimensionSummary().exists()).toBe(true);
      expect(wrapper.findByTestId('another-dimension-button').exists()).toBe(false);
    });
  });
});
