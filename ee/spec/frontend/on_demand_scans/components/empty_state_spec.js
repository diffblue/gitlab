import { mount } from '@vue/test-utils';
import EmptyState from 'ee/on_demand_scans/components/empty_state.vue';

describe('EmptyState', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(EmptyState, {
      provide: {
        newDastScanPath: '/on_demand_scans/new',
        helpPagePath: '/help/page/path',
        emptyStateSvgPath: '/empty/state/svg/path',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders properly', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });
});
