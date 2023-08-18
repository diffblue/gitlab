import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import inlineFindingsFlagSwitcher from 'ee/diffs/components/inline_findings_flag_switcher.vue';
import InlineFindingsGutterIcon from 'ee_component/diffs/components/inline_findings_gutter_icon.vue';
import InlineFindingsGutterIconDropdown from 'ee_component/diffs/components/inline_findings_gutter_icon_dropdown.vue';

let wrapper;

const findInlineFindingsGutterIcon = () => wrapper.findComponent(InlineFindingsGutterIcon);
const findInlineFindingsGutterIconDropdown = () =>
  wrapper.findComponent(InlineFindingsGutterIconDropdown);

const createComponent = (props = {}, flag) => {
  const payload = {
    provide: {
      glFeatures: {
        sastReportsInInlineDiff: flag,
      },
    },
    propsData: props,
  };
  wrapper = shallowMountExtended(inlineFindingsFlagSwitcher, payload);
};

describe('EE inlineFindingsflagSwitcher', () => {
  describe('default', () => {
    beforeEach(() => {
      createComponent({ filePath: 'test' }, true);
    });

    it('renders component without errors', () => {
      expect(wrapper.exists()).toBe(true);
    });
  });

  describe('sastReportsInInlineDiff true', () => {
    beforeEach(() => {
      createComponent({ filePath: 'test' }, true);
    });

    it('renders InlineFindingsGutterIconDropdown', () => {
      expect(findInlineFindingsGutterIconDropdown().exists()).toBe(true);
      expect(findInlineFindingsGutterIcon().exists()).toBe(false);
    });
  });

  describe('sastReportsInInlineDiff false', () => {
    beforeEach(() => {
      createComponent({ filePath: 'test' }, false);
    });

    it('renders InlineFindingsGutterIconDropdown', () => {
      expect(findInlineFindingsGutterIconDropdown().exists()).toBe(false);
      expect(findInlineFindingsGutterIcon().exists()).toBe(true);
    });
  });
});
