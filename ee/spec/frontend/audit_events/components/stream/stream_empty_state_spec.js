import { shallowMount } from '@vue/test-utils';
import { GlButton, GlEmptyState } from '@gitlab/ui';
import StreamEmptyState from 'ee/audit_events/components/stream/stream_empty_state.vue';
import { mockSvgPath } from '../../mock_data';

describe('StreamEmptyState', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(StreamEmptyState, {
      provide: {
        emptyStateSvgPath: mockSvgPath,
      },
      stubs: {
        GlEmptyState,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('should render correctly', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('should emit add event', () => {
    wrapper.findComponent(GlButton).vm.$emit('click');

    expect(wrapper.emitted('add')).toBeDefined();
  });
});
