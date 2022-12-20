import { GlFormCheckboxTree } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StreamFilters from 'ee/audit_events/components/stream/stream_filters.vue';
import { AUDIT_STREAMS_FILTERING } from 'ee/audit_events/constants';
import { mockExternalDestinations, mockFiltersOptions } from '../../mock_data';

describe('StreamWithFilters', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(StreamFilters, {
      propsData: {
        filterOptions: mockFiltersOptions,
        filterSelected: mockExternalDestinations[1].eventTypeFilters,
      },
    });
  };

  const findFilterCheckboxTree = () => wrapper.findComponent(GlFormCheckboxTree);

  beforeEach(() => {
    createComponent();
  });

  it('should render correctly', () => {
    const options = mockFiltersOptions.map((value) => ({ value }));
    expect(findFilterCheckboxTree().props()).toStrictEqual({
      hideToggleAll: false,
      label: 'Checkbox tree',
      options,
      labelSrOnly: true,
      value: mockExternalDestinations[1].eventTypeFilters,
      selectAllLabel: AUDIT_STREAMS_FILTERING.SELECT_ALL,
      unselectAllLabel: AUDIT_STREAMS_FILTERING.UNSELECT_ALL,
    });
  });

  it('should emit `updateFilters` event', () => {
    findFilterCheckboxTree().vm.$emit('change', mockExternalDestinations[1].eventTypeFilters);

    expect(wrapper.emitted('updateFilters')).toStrictEqual([
      [mockExternalDestinations[1].eventTypeFilters],
    ]);
  });
});
