import { shallowMount } from '@vue/test-utils';
import FileLocation from 'ee/vulnerabilities/components/generic_report/types/file_location.vue';

describe('ee/vulnerabilities/components/generic_report/types/file_location.vue', () => {
  let wrapper;

  describe.each`
    fileName    | lineStart | lineEnd      | value
    ${'foo.c'}  | ${4}      | ${undefined} | ${'foo.c:4'}
    ${'bar.go'} | ${2}      | ${5}         | ${'bar.go:2-5'}
  `('with value of type "$fieldType"', ({ fileName, lineStart, lineEnd, value }) => {
    const createWrapper = () => {
      return shallowMount(FileLocation, {
        propsData: {
          type: 'file-location',
          fileName,
          lineStart,
          lineEnd,
        },
      });
    };

    beforeEach(() => {
      wrapper = createWrapper();
    });

    it(`renders ${fileName} file location`, () => {
      expect(wrapper.text()).toBe(value.toString());
    });
  });
});
