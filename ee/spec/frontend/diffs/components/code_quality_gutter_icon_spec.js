import { GlIcon, GlTooltip } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CodeQualityGutterIcon from 'ee/diffs/components/code_quality_gutter_icon.vue';
import createDiffsStore from 'jest/diffs/create_diffs_store';
import { SEVERITY_CLASSES, SEVERITY_ICONS } from '~/ci/reports/codequality_report/constants';
import {
  fiveFindings,
  threeFindings,
  singularFinding,
} from '../../../../../spec/frontend/diffs/mock_data/diff_code_quality';

Vue.use(Vuex);

let wrapper;
const findIcon = () => wrapper.findComponent(GlIcon);
const findIcons = () => wrapper.findAllComponents(GlIcon);
const findFirstIcon = () => wrapper.findComponent({ ref: 'firstCodeQualityIcon' });

let store;
let codequalityDiff;

const createComponent = (props = {}) => {
  store = createDiffsStore();
  store.state.diffs.codequalityDiff = codequalityDiff;

  const payload = {
    propsData: props,
    store,
  };

  wrapper = shallowMountExtended(CodeQualityGutterIcon, payload);
};

describe('EE CodeQualityGutterIcon', () => {
  const containsATooltip = (container) => container.findComponent(GlTooltip).exists();

  it.each`
    severity
    ${'info'}
    ${'minor'}
    ${'major'}
    ${'critical'}
    ${'blocker'}
    ${'unknown'}
  `('shows icon for $severity degradation', ({ severity }) => {
    createComponent({ filePath: 'index.js', codequality: [{ severity }] });

    expect(findIcon().exists()).toBe(true);
    expect(findIcon().attributes()).toMatchObject({
      class: expect.stringContaining(SEVERITY_CLASSES[severity]),
      name: SEVERITY_ICONS[severity],
      size: '16',
    });
  });

  describe('code quality gutter icon', () => {
    describe('with maximum 3 findings', () => {
      beforeEach(() => {
        createComponent(threeFindings, true);
      });

      it('contains a tooltip', () => {
        expect(containsATooltip(wrapper)).toBe(true);
      });

      it('displays correct popover text with multiple codequality findings', () => {
        expect(wrapper.findComponent(GlTooltip).text()).toContain('3 Code quality findings');
      });

      it('emits showCodeQualityFindings event on click', () => {
        wrapper.trigger('click');
        expect(wrapper.emitted('showCodeQualityFindings')).toHaveLength(1);
      });

      it('displays first icon with correct severity', () => {
        const icons = findIcons();
        expect(icons).toHaveLength(1);
        expect(icons.at(0).props().name).toBe('severity-low');
      });

      it('displays correct amount of icons with correct severity on hover', async () => {
        findFirstIcon().vm.$emit('mouseenter');
        await nextTick();
        const icons = findIcons();
        expect(icons).toHaveLength(3);
        expect(icons.at(0).props().name).toBe('severity-low');
        expect(icons.at(1).props().name).toBe('severity-medium');
        expect(icons.at(2).props().name).toBe('severity-info');
      });

      it('does not display more count', () => {
        expect(wrapper.findByTestId('codeQualityMoreCount').exists()).toBe(false);
      });
    });

    describe('with more than 3 findings', () => {
      beforeEach(() => {
        createComponent(fiveFindings, true);
      });

      it('displays first icon with correct severity', () => {
        const icons = findIcons();
        expect(icons).toHaveLength(1);
        expect(icons.at(0).props().name).toBe('severity-low');
      });

      it('displays correct amount of icons with correct severity + more count on hover', async () => {
        findFirstIcon().vm.$emit('mouseenter');
        await nextTick();
        const icons = findIcons();
        expect(icons).toHaveLength(3);
        expect(icons.at(0).props().name).toBe('severity-low');
        expect(icons.at(1).props().name).toBe('severity-medium');
        expect(icons.at(2).props().name).toBe('severity-info');
        expect(wrapper.findByTestId('codeQualityMoreCount').exists()).toBe(true);
      });
    });

    describe('with singular finding', () => {
      beforeEach(() => {
        createComponent(singularFinding, true);
      });

      it('displays correct popover text with singular codequality finding', () => {
        expect(wrapper.findComponent(GlTooltip).text()).toContain('1 Code quality finding');
      });

      it('does not trigger "first-icon-hovered" class when firstCodeQualityIcon is hovered', async () => {
        findFirstIcon().vm.$emit('mouseenter');
        await nextTick();
        expect(wrapper.findAll('.first-icon-hovered')).toHaveLength(0);
      });
    });

    describe('indicator icon', () => {
      describe('with codeQualityExpanded prop false', () => {
        beforeEach(() => {
          createComponent(singularFinding, true);
        });

        it('shows severity icon with correct tooltip', () => {
          expect(wrapper.findComponent(GlTooltip).text()).toContain('1 Code quality finding');
          expect(wrapper.findComponent(GlIcon).props().name).toBe('severity-low');
        });
      });
      describe('with codeQualityExpanded prop true', () => {
        beforeEach(() => {
          createComponent({ ...singularFinding, codeQualityExpanded: true }, true);
        });

        it('shows collapse icon', () => {
          expect(wrapper.findComponent(GlIcon).props().name).toBe('collapse');
        });
      });
    });
  });
});
