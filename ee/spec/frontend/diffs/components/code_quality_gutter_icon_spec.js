import { GlIcon, GlTooltip } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CodeQualityGutterIcon from 'ee/diffs/components/code_quality_gutter_icon.vue';
import store from '~/mr_notes/stores';
import { SEVERITY_CLASSES, SEVERITY_ICONS } from '~/ci/reports/codequality_report/constants';

import {
  fiveCodeQualityFindings,
  threeCodeQualityFindings,
  threeSastFindings,
  singularCodeQualityFinding,
  singularFindingSast,
  oneCodeQualityTwoSastFindings,
} from '../../../../../spec/frontend/diffs/mock_data/inline_findings';

jest.mock('~/mr_notes/stores', () => jest.requireActual('helpers/mocks/mr_notes/stores'));

let wrapper;
const findIcon = () => wrapper.findComponent(GlIcon);
const findIcons = () => wrapper.findAllComponents(GlIcon);
const findFirstIcon = () => wrapper.findComponent({ ref: 'firstCodeQualityIcon' });

let codequalityDiff;

const createComponent = (props = {}) => {
  store.reset();
  store.state.diffs.codequalityDiff = codequalityDiff;

  const payload = {
    propsData: props,
    mocks: {
      $store: store,
    },
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

  describe('code Quality gutter icon', () => {
    describe('with no findings', () => {
      beforeEach(() => {
        createComponent({ filePath: 'test' }, true);
      });

      it('renders component without errors', () => {
        expect(wrapper.exists()).toBe(true);
      });
    });

    describe('with maximum 3 code Quality findings', () => {
      beforeEach(() => {
        createComponent(threeCodeQualityFindings, true);
      });

      it('contains a tooltip', () => {
        expect(containsATooltip(wrapper)).toBe(true);
      });

      it('displays correct popover text with multiple codequality findings', () => {
        expect(wrapper.findComponent(GlTooltip).text()).toContain('3 Code Quality findings');
      });

      it('emits showCodeQualityFindings event on click', () => {
        wrapper.trigger('click');
        expect(wrapper.emitted('showCodeQualityFindings')).toHaveLength(1);
      });

      it('displays first icon with correct severity', () => {
        const icons = findIcons();
        expect(icons).toHaveLength(1);
        expect(icons.at(0).props('name')).toBe('severity-low');
      });

      it('displays correct amount of icons with correct severity on hover', async () => {
        findFirstIcon().vm.$emit('mouseenter');
        await nextTick();
        const icons = findIcons();
        expect(icons).toHaveLength(3);
        expect(icons.at(0).props('name')).toBe('severity-low');
        expect(icons.at(1).props('name')).toBe('severity-medium');
        expect(icons.at(2).props('name')).toBe('severity-info');
      });

      it('does not display more count', () => {
        expect(wrapper.findByTestId('codeQualityMoreCount').exists()).toBe(false);
      });
    });

    describe('with maximum 3 Sast Findings findings', () => {
      beforeEach(() => {
        createComponent(threeSastFindings, true);
      });

      afterEach(() => {
        if (wrapper) {
          wrapper = null;
        }
      });

      it('contains a tooltip', () => {
        expect(containsATooltip(wrapper)).toBe(true);
      });

      it('displays correct popover text with multiple codequality findings', () => {
        expect(wrapper.findComponent(GlTooltip).text()).toContain('3 Security findings');
      });

      it('emits showCodeQualityFindings event on click', () => {
        wrapper.trigger('click');
        expect(wrapper.emitted('showCodeQualityFindings')).toHaveLength(1);
      });

      it('displays first icon with correct severity', () => {
        const icons = findIcons();
        expect(icons).toHaveLength(1);
        expect(icons.at(0).props('name')).toBe('severity-low');
      });

      it('displays correct amount of icons with correct severity on hover', async () => {
        findFirstIcon().vm.$emit('mouseenter');
        await nextTick();
        const icons = findIcons();
        expect(icons).toHaveLength(3);
        expect(icons.at(0).props('name')).toBe('severity-low');
        expect(icons.at(1).props('name')).toBe('severity-medium');
        expect(icons.at(2).props('name')).toBe('severity-info');
      });

      it('does not display more count', () => {
        expect(wrapper.findByTestId('codeQualityMoreCount').exists()).toBe(false);
      });
    });

    describe('with maximum 3 Sast and codequality Findings findings', () => {
      beforeEach(() => {
        createComponent(oneCodeQualityTwoSastFindings, true);
      });

      afterEach(() => {
        if (wrapper) {
          wrapper = null;
        }
      });

      it('contains a tooltip', () => {
        expect(containsATooltip(wrapper)).toBe(true);
      });

      it('displays correct popover text with multiple codequality findings', () => {
        expect(wrapper.findComponent(GlTooltip).text()).toContain(
          '1 Code Quality finding 2 Security findings',
        );
      });

      it('emits showCodeQualityFindings event on click', () => {
        wrapper.trigger('click');
        expect(wrapper.emitted('showCodeQualityFindings')).toHaveLength(1);
      });

      it('displays first icon with correct severity', () => {
        const icons = findIcons();
        expect(icons).toHaveLength(1);
        expect(icons.at(0).props('name')).toBe('severity-low');
      });

      it('displays correct amount of icons with correct severity on hover', async () => {
        findFirstIcon().vm.$emit('mouseenter');
        await nextTick();
        const icons = findIcons();
        expect(icons).toHaveLength(3);
        expect(icons.at(0).props('name')).toBe('severity-low');
        expect(icons.at(1).props('name')).toBe('severity-low');
        expect(icons.at(2).props('name')).toBe('severity-medium');
      });

      it('does not display more count', () => {
        expect(wrapper.findByTestId('codeQualityMoreCount').exists()).toBe(false);
      });
    });

    describe('with more than 3 codequality findings', () => {
      beforeEach(() => {
        createComponent(fiveCodeQualityFindings, true);
      });

      it('displays first icon with correct severity', () => {
        const icons = findIcons();
        expect(icons).toHaveLength(1);
        expect(icons.at(0).props('name')).toBe('severity-low');
      });

      it('displays correct amount of icons with correct severity + more count on hover', async () => {
        findFirstIcon().vm.$emit('mouseenter');
        await nextTick();
        const icons = findIcons();
        expect(icons).toHaveLength(3);
        expect(icons.at(0).props('name')).toBe('severity-low');
        expect(icons.at(1).props('name')).toBe('severity-medium');
        expect(icons.at(2).props('name')).toBe('severity-info');
        expect(wrapper.findByTestId('codeQualityMoreCount').exists()).toBe(true);
      });
    });

    describe('with singular finding', () => {
      it('displays correct popover text with singular codequality finding', () => {
        createComponent(singularCodeQualityFinding, true);
        expect(wrapper.findComponent(GlTooltip).text()).toContain('1 Code Quality finding');
      });

      it('displays correct popover text with singular Sast finding', () => {
        createComponent(singularFindingSast, true);
        expect(wrapper.findComponent(GlTooltip).text()).toContain('1 Security finding');
      });

      it('does not trigger "first-icon-hovered" class when firstCodeQualityIcon is hovered', async () => {
        createComponent(singularCodeQualityFinding, true);
        findFirstIcon().vm.$emit('mouseenter');
        await nextTick();
        expect(wrapper.findAll('.first-icon-hovered')).toHaveLength(0);
      });
    });

    describe('indicator icon', () => {
      describe('with codeQualityExpanded prop false', () => {
        beforeEach(() => {
          createComponent(singularCodeQualityFinding, true);
        });

        it('shows severity icon with correct tooltip', () => {
          expect(wrapper.findComponent(GlTooltip).text()).toContain('1 Code Quality finding');
          expect(wrapper.findComponent(GlIcon).props('name')).toBe('severity-low');
        });
      });
      describe('with codeQualityExpanded prop true', () => {
        beforeEach(() => {
          createComponent({ ...singularCodeQualityFinding, codeQualityExpanded: true }, true);
        });

        it('shows collapse icon', () => {
          expect(wrapper.findComponent(GlIcon).props('name')).toBe('collapse');
        });
      });
    });
  });
});
