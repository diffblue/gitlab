import { mount } from '@vue/test-utils';
import Diff from 'ee/vulnerabilities/components/generic_report/types/diff.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const TEST_DATA = {
  before: `beforeText`,
  after: `afterText`,
};

describe('ee/vulnerabilities/components/generic_report/types/diff.vue', () => {
  let wrapper;

  const createWrapper = () => {
    return extendedWrapper(
      mount(Diff, {
        propsData: {
          ...TEST_DATA,
        },
      }),
    );
  };

  beforeEach(() => {
    wrapper = createWrapper();
  });

  const findButton = (type) => wrapper.findByTestId(`${type}Button`);
  const findDiffOutput = () => wrapper.find('.code').text();
  const findDiffLines = () => wrapper.findAllByTestId('diffLine');

  describe.each`
    viewType    | expectedLines | includesBeforeText | includesAfterText
    ${'diff'}   | ${2}          | ${true}            | ${true}
    ${'before'} | ${1}          | ${true}            | ${false}
    ${'after'}  | ${1}          | ${false}           | ${true}
  `(
    'with "$viewType" selected',
    ({ viewType, expectedLines, includesBeforeText, includesAfterText }) => {
      beforeEach(() => findButton(viewType).trigger('click'));

      it(`shows $expectedLines`, () => {
        expect(findDiffLines()).toHaveLength(expectedLines);
      });

      it(`${includesBeforeText ? 'includes' : 'does not include'} before text`, () => {
        expect(findDiffOutput().includes(TEST_DATA.before)).toBe(includesBeforeText);
      });

      it(`${includesAfterText ? 'includes' : 'does not include'} after text`, () => {
        expect(findDiffOutput().includes(TEST_DATA.after)).toBe(includesAfterText);
      });
    },
  );
});
