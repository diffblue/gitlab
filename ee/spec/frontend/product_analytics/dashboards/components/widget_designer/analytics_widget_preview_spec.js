import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AnalyticsWidgetPreview from 'ee/product_analytics/dashboards/components/widget_designer/analytics_widget_preview.vue';

import { WIDGET_DISPLAY_TYPES } from 'ee/product_analytics/dashboards/constants';

describe('AnalyticsWidgetPreview', () => {
  let wrapper;

  const findDataButton = () => wrapper.findByTestId('select-data-button');
  const findWidgetButton = () => wrapper.findByTestId('select-widget-button');
  const findCodeButton = () => wrapper.findByTestId('select-code-button');

  const selectDisplayType = jest.fn();

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(AnalyticsWidgetPreview, {
      propsData: {
        selectedVisualizationType: '',
        displayType: '',
        selectDisplayType,
        isQueryPresent: false,
        loading: false,
        resultSet: { tablePivot: () => {} },
        resultWidget: {},
        ...props,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render measurement headline', () => {
      expect(wrapper.findByTestId('measurement-hl').exists()).toBe(true);
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createWrapper({ isQueryPresent: true, loading: true });
    });

    it('should render loading icon', () => {
      expect(wrapper.findByTestId('loading-icon').exists()).toBe(true);
    });
  });

  describe('when it has a resultSet', () => {
    beforeEach(() => {
      createWrapper({
        isQueryPresent: true,
      });
    });

    it('should render overview buttons', () => {
      expect(findDataButton().exists()).toBe(true);
      expect(findWidgetButton().exists()).toBe(true);
      expect(findCodeButton().exists()).toBe(true);
    });

    it('should be able to select data section', () => {
      findDataButton().vm.$emit('click');
      expect(wrapper.emitted('selectedDisplayType')).toEqual([[WIDGET_DISPLAY_TYPES.DATA]]);
    });

    it('should be able to select widget section', () => {
      findWidgetButton().vm.$emit('click');
      expect(wrapper.emitted('selectedDisplayType')).toEqual([[WIDGET_DISPLAY_TYPES.WIDGET]]);
    });

    it('should be able to select code section', () => {
      findCodeButton().vm.$emit('click');
      expect(wrapper.emitted('selectedDisplayType')).toEqual([[WIDGET_DISPLAY_TYPES.CODE]]);
    });
  });

  describe('resultSet and data is selected', () => {
    beforeEach(() => {
      createWrapper({
        isQueryPresent: true,
        displayType: WIDGET_DISPLAY_TYPES.DATA,
      });
    });

    it('should render data table', () => {
      expect(wrapper.findByTestId('preview-datatable').exists()).toBe(true);
    });
  });

  describe('resultSet and widget is selected', () => {
    beforeEach(() => {
      createWrapper({
        isQueryPresent: true,
        displayType: WIDGET_DISPLAY_TYPES.WIDGET,
        selectedVisualizationType: 'LineChart',
      });
    });

    it('should render widget', () => {
      expect(wrapper.findByTestId('preview-widget').exists()).toBe(true);
    });
  });

  describe('resultSet and code is selected', () => {
    beforeEach(() => {
      createWrapper({
        isQueryPresent: true,
        displayType: WIDGET_DISPLAY_TYPES.CODE,
      });
    });

    it('should render Code', () => {
      expect(wrapper.findByTestId('preview-code').exists()).toBe(true);
    });
  });
});
