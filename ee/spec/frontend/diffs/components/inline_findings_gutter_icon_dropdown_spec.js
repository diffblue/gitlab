import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import inlineFindingsGutterIconDropdown from 'ee/diffs/components/inline_findings_gutter_icon_dropdown.vue';
import inlineFindingsDropdown from 'ee/diffs/components/inline_findings_dropdown.vue';
import { getSeverity } from '~/ci/reports/utils';

import {
  fiveCodeQualityFindings,
  singularCodeQualityFinding,
  singularSastFinding,
  filePath,
} from 'jest/diffs/mock_data/inline_findings';

jest.mock('~/mr_notes/stores', () => jest.requireActual('helpers/mocks/mr_notes/stores'));

let wrapper;
const findInlineFindingsDropdown = () => wrapper.findComponent(inlineFindingsDropdown);
const findMoreCount = () => wrapper.findByTestId('inline-findings-more-count');

const createComponent = (
  props = {
    filePath,
    codeQuality: singularCodeQualityFinding,
  },
) => {
  const payload = {
    propsData: props,
  };
  wrapper = shallowMountExtended(inlineFindingsGutterIconDropdown, payload);
};

describe('EE inlineFindingsGutterIconDropdown', () => {
  describe('code Quality gutter icon', () => {
    describe('flatFindings', () => {
      it('computes correctly', () => {
        createComponent({
          filePath,
          codeQuality: singularCodeQualityFinding,
          sast: singularSastFinding,
        });

        const combinedResult = [];
        combinedResult.push(getSeverity(singularCodeQualityFinding[0]));
        combinedResult.push(getSeverity(singularSastFinding[0]));
        expect(wrapper.vm.flatFindings).toEqual(combinedResult);
      });
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
      it('computes correctly', () => {
        createComponent({
          filePath,
          codeQuality: singularCodeQualityFinding,
          sast: singularSastFinding,
        });

        expect(wrapper.vm.groupedFindings).toEqual([
          {
            name: '1 Code Quality finding detected',
            items: getSeverity(singularCodeQualityFinding),
          },
          {
            name: '1 SAST finding detected',
            items: getSeverity(singularSastFinding),
          },
        ]);
      });

      it('renders inlineFindingsDropdown component with correct props', () => {
        createComponent({
          filePath,
          codeQuality: singularCodeQualityFinding,
          sast: singularSastFinding,
        });

        expect(findInlineFindingsDropdown().exists()).toBe(true);
        expect(findInlineFindingsDropdown().props('items')).toEqual(wrapper.vm.groupedFindings);

        expect(findInlineFindingsDropdown().props('iconId')).toEqual(
          `${wrapper.vm.filePath}-${wrapper.vm.flatFindings[0].line}`,
        );

        expect(findInlineFindingsDropdown().props('iconKey')).toEqual(
          wrapper.vm.firstItem.description,
        );

        expect(findInlineFindingsDropdown().props('iconName')).toEqual(
          wrapper.vm.flatFindings[0].name,
        );

        expect(findInlineFindingsDropdown().props('iconClass')).toEqual(
          wrapper.vm.flatFindings[0].class,
        );
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
