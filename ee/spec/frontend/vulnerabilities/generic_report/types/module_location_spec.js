import { shallowMount } from '@vue/test-utils';
import ModuleLocation from 'ee/vulnerabilities/components/generic_report/types/module_location.vue';

describe('ee/vulnerabilities/components/generic_report/types/module_location.vue', () => {
  let wrapper;

  describe.each`
    moduleName  | offset | value
    ${'foo.c'}  | ${4}   | ${'foo.c:4'}
    ${'bar.go'} | ${2}   | ${'bar.go:2'}
  `('with value of type "$fieldType"', ({ moduleName, offset, value }) => {
    const createWrapper = () => {
      return shallowMount(ModuleLocation, {
        propsData: {
          type: 'module-location',
          moduleName,
          offset,
        },
      });
    };

    beforeEach(() => {
      wrapper = createWrapper();
    });

    it(`renders ${moduleName} module`, () => {
      expect(wrapper.text()).toBe(value.toString());
    });
  });
});
