import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DateRangeButtons from 'ee/audit_events/components/date_range_buttons.vue';
import { CURRENT_DATE } from 'ee/audit_events/constants';
import { getDateInPast } from '~/lib/utils/datetime_utility';

describe('DateRangeButtons component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DateRangeButtons, {
      propsData: { ...props },
    });
  };

  const findButtonGroup = () => wrapper.findComponent(GlButtonGroup);
  const findButtons = (f) => findButtonGroup().findAllComponents(GlButton).filter(f);
  const findSelectedButtons = () => findButtons((b) => b.props('selected'));
  const findUnSelectedButtons = () => findButtons((b) => !b.props('selected'));

  afterEach(() => {
    wrapper.destroy();
  });

  it('sets the tracking data on the button', () => {
    createComponent({
      dateRange: { startDate: getDateInPast(CURRENT_DATE, 7), endDate: CURRENT_DATE },
    });

    expect(findSelectedButtons().at(0).attributes()).toMatchObject({
      'data-track-action': 'click_date_range_button',
      'data-track-label': 'date_range_button_last_7_days',
    });
  });

  it('shows the selected the option that matches the provided dateRange property', () => {
    createComponent({
      dateRange: { startDate: getDateInPast(CURRENT_DATE, 7), endDate: CURRENT_DATE },
    });

    expect(findSelectedButtons().at(0).text()).toBe('Last 7 days');
  });

  it('shows no date range as selected when the dateRange property does not match any option', () => {
    createComponent({
      dateRange: {
        startDate: getDateInPast(CURRENT_DATE, 5),
        endDate: getDateInPast(CURRENT_DATE, 2),
      },
    });

    expect(findSelectedButtons()).toHaveLength(0);
  });

  it('emits an "input" event with the dateRange when a new date range is selected', async () => {
    createComponent({
      dateRange: { startDate: getDateInPast(CURRENT_DATE, 7), endDate: CURRENT_DATE },
    });
    findUnSelectedButtons().at(0).vm.$emit('click');

    await wrapper.vm.$nextTick();
    expect(wrapper.emitted().input[0]).toEqual([
      {
        startDate: getDateInPast(CURRENT_DATE, 14),
        endDate: CURRENT_DATE,
      },
    ]);
  });
});
