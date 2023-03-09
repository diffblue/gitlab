import { shallowMount } from '@vue/test-utils';
import Text from 'ee/vulnerabilities/components/generic_report/types/value.vue';

describe('ee/vulnerabilities/components/generic_report/types/value.vue', () => {
  let wrapper;

  describe.each`
    fieldType    | value
    ${'string'}  | ${'some string'}
    ${'number'}  | ${8}
    ${'boolean'} | ${true}
    ${'boolean'} | ${false}
  `('with value of type "$fieldType"', ({ fieldType, value }) => {
    const createWrapper = () => {
      return shallowMount(Text, {
        propsData: {
          type: 'text',
          name: `${fieldType} field`,
          value,
        },
      });
    };

    beforeEach(() => {
      wrapper = createWrapper();
    });

    it(`renders ${fieldType} type`, () => {
      expect(wrapper.text()).toBe(value.toString());
    });
  });
});
