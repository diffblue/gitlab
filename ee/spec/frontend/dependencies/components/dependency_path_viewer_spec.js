import { mount } from '@vue/test-utils';
import DependencyPathViewer from 'ee/dependencies/components/dependency_path_viewer.vue';

describe('DependencyPathViewer component', () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = mount(DependencyPathViewer, {
      ...options,
    });
  };

  it.each`
    dependencies                                                                  | path
    ${[]}                                                                         | ${''}
    ${[{ name: 'emmajsq' }]}                                                      | ${'emmajsq'}
    ${[{ name: 'emmajsq', version: '10.11' }]}                                    | ${'emmajsq 10.11'}
    ${[{ name: 'emmajsq' }, { name: 'swell' }]}                                   | ${'emmajsq / swell'}
    ${[{ name: 'emmajsq', version: '10.11' }, { name: 'swell', version: '1.2' }]} | ${'emmajsq 10.11 / swell 1.2'}
  `('shows complete dependency path for $path', ({ dependencies, path }) => {
    factory({
      propsData: { dependencies },
    });

    expect(wrapper.text()).toBe(path);
  });
});
