import { shallowMount } from '@vue/test-utils';
import ChartTooltipText from 'ee/analytics/shared/components/chart_tooltip_text.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const emptyValueText = 'This is empty';
const metric = { title: 'Cool tip', value: 10 };
const tooltipValue = [metric];

const createComponent = (props = {}) =>
  extendedWrapper(
    shallowMount(ChartTooltipText, {
      propsData: {
        emptyValueText,
        tooltipValue,
        ...props,
      },
    }),
  );

describe('ChartTooltipText', () => {
  let wrapper = null;

  const findTooltipValue = () => wrapper.findByTestId('tooltip-value');

  describe('with tooltipValue data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the tooltip', () => {
      expect(wrapper.text()).toContain(metric.title);
      expect(Number(findTooltipValue().text())).toBe(metric.value);
      expect(wrapper.html()).toMatchSnapshot();
    });

    it('does not render the tooltip empty state text', () => {
      expect(wrapper.text()).not.toContain(emptyValueText);
    });
  });

  describe('with no tooltipValue data', () => {
    beforeEach(() => {
      wrapper = createComponent({ tooltipValue: [] });
    });

    it('does not renders the tooltip', () => {
      expect(wrapper.text()).not.toContain(metric.title);
      expect(findTooltipValue().exists()).toBe(false);
    });

    it('renders the tooltip empty state text', () => {
      expect(wrapper.html()).toMatchSnapshot();
      expect(wrapper.text()).toContain(emptyValueText);
    });
  });
});
