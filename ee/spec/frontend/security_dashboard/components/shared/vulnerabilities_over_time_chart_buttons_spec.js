import { GlSegmentedControl } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import VulnerabilitiesOverTimeChartButtons from 'ee/security_dashboard/components/shared/vulnerabilities_over_time_chart_buttons.vue';
import { DAYS } from 'ee/security_dashboard/store/constants';

describe('Vulnerability Chart Buttons', () => {
  let wrapper;
  const days = Object.values(DAYS);

  const findSegmentedControlButtons = () => wrapper.findComponent(GlSegmentedControl);

  const createWrapper = (props = { activeDay: DAYS.thirty }) => {
    wrapper = shallowMountExtended(VulnerabilitiesOverTimeChartButtons, {
      propsData: { days, ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should pass the correct options to the segmented control group', () => {
    createWrapper();

    expect(findSegmentedControlButtons().props('options')).toStrictEqual([
      { value: DAYS.thirty, text: '30 Days' },
      { value: DAYS.sixty, text: '60 Days' },
      { value: DAYS.ninety, text: '90 Days' },
    ]);
  });

  it.each(days)('should set "%s days" as selected', (activeDay) => {
    createWrapper({ activeDay });

    expect(findSegmentedControlButtons().props('checked')).toBe(activeDay);
  });

  it('should emit a "days-selected" event with the correct payload when the selection changes', () => {
    createWrapper();

    expect(wrapper.emitted('days-selected')).toBeFalsy();

    findSegmentedControlButtons().vm.$emit('input', DAYS.thirty);

    expect(wrapper.emitted('days-selected')).toEqual([[DAYS.thirty]]);
  });
});
