import { mount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import EmptyState from 'ee/on_demand_scans/components/empty_state.vue';

describe('EmptyState', () => {
  let wrapper;

  // Finders
  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);

  // Helpers
  const defaultGlEmptyStateProp = (prop) => GlEmptyState.props[prop].default;

  const createComponent = (propsData = {}) => {
    wrapper = mount(EmptyState, {
      provide: {
        newDastScanPath: '/on_demand_scans/new',
        emptyStateSvgPath: '/empty/state/svg/path',
      },
      propsData,
    });
  };

  it('renders properly', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('passes custom title down to GlEmptyState', () => {
    const title = 'Custom title';
    createComponent({
      title,
    });

    expect(findGlEmptyState().props('title')).toBe(title);
  });

  it('passes custom text down to GlEmptyState', () => {
    const text = 'Custom text';
    createComponent({
      text,
    });

    expect(findGlEmptyState().text()).toMatch(text);
  });

  it('does not pass primary props when no-primary-button is true', () => {
    createComponent({
      noPrimaryButton: true,
    });

    expect(findGlEmptyState().props('primaryButtonLink')).toBe(
      defaultGlEmptyStateProp('primaryButtonLink'),
    );
    expect(findGlEmptyState().props('primaryButtonLink')).toBe(
      defaultGlEmptyStateProp('primaryButtonLink'),
    );
  });
});
