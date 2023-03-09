import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import VulnerabilitiesOverTimeChartButtons from 'ee/security_dashboard/components/shared/vulnerabilities_over_time_chart_buttons.vue';

const TEST_DAYS = [1, 30, 60, 90];

describe('Vulnerability Chart Buttons', () => {
  let wrapper;

  const findAllButtons = () => wrapper.findAllComponents(GlButton);
  const findAllActiveButtons = () => findAllButtons().filter((button) => button.props('selected'));
  const findButtonForDay = (day) => findAllButtons().at(TEST_DAYS.indexOf(day));

  const createWrapper = (props) => {
    wrapper = shallowMountExtended(VulnerabilitiesOverTimeChartButtons, {
      propsData: { days: TEST_DAYS, activeDay: TEST_DAYS[0], ...props },
    });
  };

  it.each(TEST_DAYS)('should display a button for "%s" days', (day) => {
    const isMultipleDays = day > 1;
    createWrapper();

    expect(findButtonForDay(day).text()).toBe(`${day} ${isMultipleDays ? 'Days' : 'Day'}`);
  });

  it.each(TEST_DAYS)('should set "%s days" as selected', (activeDay) => {
    createWrapper({ activeDay });

    expect(findAllActiveButtons()).toHaveLength(1);
    expect(findButtonForDay(activeDay).props('selected')).toBe(true);
  });

  it('should emit a "days-selected" event with the correct payload when the selection changes', () => {
    createWrapper();

    expect(wrapper.emitted('days-selected')).toBeUndefined();

    findAllButtons().at(0).vm.$emit('click');

    expect(wrapper.emitted('days-selected')).toEqual([[TEST_DAYS[0]]]);
  });
});
