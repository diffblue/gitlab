import Vue, { nextTick } from 'vue';

// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import inlineFindingsGutterIconDropdown from 'ee/diffs/components/inline_findings_gutter_icon_dropdown.vue';
import inlineFindingsDropdown from 'ee/diffs/components/inline_findings_dropdown.vue';

import {
  fiveCodeQualityFindings,
  singularCodeQualityFinding,
  singularSastFinding,
  filePath,
} from 'jest/diffs/mock_data/inline_findings';

jest.mock('~/mr_notes/stores', () => jest.requireActual('helpers/mocks/mr_notes/stores'));
Vue.use(Vuex);

let store;
let wrapper;
const mockSetDrawer = jest.fn();

const findInlineFindingsDropdown = () => wrapper.findComponent(inlineFindingsDropdown);
const findMoreCount = () => wrapper.findByTestId('inline-findings-more-count');
const findDropdownItems = () => wrapper.findAll('.gl-new-dropdown-item-content');
const createComponent = (
  props = {
    filePath,
    codeQuality: singularCodeQualityFinding,
  },
) => {
  const payload = {
    propsData: props,
    store,
  };
  wrapper = mountExtended(inlineFindingsGutterIconDropdown, payload);
};

describe('EE inlineFindingsGutterIconDropdown', () => {
  describe('code Quality gutter icon', () => {
    it('renders correctly', () => {
      createComponent({
        filePath,
        codeQuality: singularCodeQualityFinding,
        sast: singularSastFinding,
      });

      expect(findInlineFindingsDropdown().exists()).toBe(true);
    });

    describe('more count', () => {
      it('renders when there are more than 3 findings and icon is hovered', async () => {
        createComponent({
          filePath: '/',
          codeQuality: fiveCodeQualityFindings,
        });

        findInlineFindingsDropdown().vm.$emit('mouseenter');
        await nextTick();

        expect(findMoreCount().text()).toBe('2');
      });

      it('does not render when there are less than 3 findings and icon is hovered', async () => {
        createComponent({
          filePath: '/',
          codeQuality: singularCodeQualityFinding,
        });

        findInlineFindingsDropdown().vm.$emit('mouseenter');
        await nextTick();

        expect(findMoreCount().exists()).toBe(false);
      });
    });

    describe('groupedFindings', () => {
      beforeEach(() => {
        mockSetDrawer.mockReset();

        const findingsDrawerModule = {
          namespaced: true,
          actions: {
            setDrawer: mockSetDrawer,
          },
        };

        store = new Vuex.Store({
          modules: {
            findingsDrawer: findingsDrawerModule,
          },
        });
      });

      it('calls setDrawer action when an item action is triggered', async () => {
        createComponent({
          filePath,
          codeQuality: singularCodeQualityFinding,
          sast: singularSastFinding,
        });

        const itemElements = findDropdownItems();

        // check for CodeQuality
        await itemElements.at(0).trigger('click');
        expect(mockSetDrawer).toHaveBeenCalledTimes(1);

        // check for SAST
        await itemElements.at(1).trigger('click');
        expect(mockSetDrawer).toHaveBeenCalledTimes(2);
      });
    });

    it('sets "isHoveringFirstIcon" to true when mouse enters the first icon', async () => {
      createComponent();

      findInlineFindingsDropdown().vm.$emit('mouseenter');
      await nextTick();

      expect(wrapper.vm.isHoveringFirstIcon).toBe(true);
    });

    it('sets "isHoveringFirstIcon" to false when mouse leaves the first icon', async () => {
      createComponent();

      findInlineFindingsDropdown().vm.$emit('mouseleave');
      await nextTick();

      expect(wrapper.vm.isHoveringFirstIcon).toBe(false);
    });
  });
});
