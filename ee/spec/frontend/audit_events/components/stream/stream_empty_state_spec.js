import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlEmptyState } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import StreamEmptyState from 'ee/audit_events/components/stream/stream_empty_state.vue';
import { mockSvgPath, groupPath } from '../../mock_data';

describe('StreamEmptyState', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(StreamEmptyState, {
      provide: {
        emptyStateSvgPath: mockSvgPath,
        groupPath,
      },
      stubs: {
        GlEmptyState,
      },
    });
  };

  const findAddDestinationButton = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDisclosureDropdownItem = (index) =>
    wrapper.findAllComponents(GlDisclosureDropdownItem).at(index).find('button');
  const findHttpDropdownItem = () => findDisclosureDropdownItem(0);
  const findGcpLoggingDropdownItem = () => findDisclosureDropdownItem(1);

  beforeEach(() => {
    createComponent();
  });

  it('should render correctly', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('should show options', () => {
    expect(findAddDestinationButton().exists()).toBe(true);
    expect(findAddDestinationButton().props('toggleText')).toBe('Add streaming destination');
  });

  it('emits event on select http', async () => {
    await findHttpDropdownItem().trigger('click');
    expect(wrapper.emitted('add')).toStrictEqual([['http']]);
  });

  it('emits event on select gcp logging', async () => {
    await findGcpLoggingDropdownItem().trigger('click');
    expect(wrapper.emitted('add')).toStrictEqual([['gcpLogging']]);
  });
});
