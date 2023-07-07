import { GlIcon, GlTruncate } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DependencyLocationCount from 'ee/dependencies/components/dependency_location_count.vue';

describe('Dependency Location Count component', () => {
  let wrapper;

  const createComponent = ({ propsData, ...options } = {}) => {
    wrapper = shallowMount(DependencyLocationCount, {
      propsData: { ...propsData },
      stubs: { GlTruncate },
      ...options,
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);

  it('renders location text and icon', () => {
    createComponent({
      propsData: {
        locationCount: 2,
      },
    });

    expect(wrapper.text()).toContain('2 locations');
    expect(findIcon().props('name')).toBe('doc-text');
  });
});
