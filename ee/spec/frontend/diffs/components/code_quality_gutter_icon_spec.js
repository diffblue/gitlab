import { GlPopover, GlIcon, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import CodeQualityGutterIcon from 'ee/diffs/components/code_quality_gutter_icon.vue';
import createDiffsStore from 'jest/diffs/create_diffs_store';
import CodequalityIssueBody from '~/reports/codequality_report/components/codequality_issue_body.vue';
import { SEVERITY_CLASSES, SEVERITY_ICONS } from '~/reports/codequality_report/constants';
import {
  multipleFindings,
  singularFinding,
} from '../../../../../spec/frontend/diffs/mock_data/diff_code_quality';

Vue.use(Vuex);

let wrapper;
const findIcon = () => wrapper.findComponent(GlIcon);
let store;
let codequalityDiff;

const createComponent = (props = {}, flag = false) => {
  store = createDiffsStore();
  store.state.diffs.codequalityDiff = codequalityDiff;

  const payload = {
    propsData: { ...multipleFindings, ...props },
    provide: {
      glFeatures: {
        refactorCodeQualityInlineFindings: flag,
      },
    },
    store,
  };

  wrapper = shallowMount(CodeQualityGutterIcon, payload);
};

describe('EE CodeQualityGutterIcon with flag off', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it.each(['info', 'minor', 'major', 'critical', 'blocker', 'unknown'])(
    'shows icon for %s degradation',
    (severity) => {
      createComponent({ codequality: [{ severity }] });

      expect(findIcon().exists()).toBe(true);
      expect(findIcon().attributes()).toMatchObject({
        class: expect.stringContaining(SEVERITY_CLASSES[severity]),
        name: SEVERITY_ICONS[severity],
        size: '12',
      });
    },
  );

  describe('code quality gutter icon', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a popover on hover', () => {
      const popoverTarget = 'codequality-index.js:2';

      wrapper.findComponent(GlIcon).trigger('mouseover');

      expect(wrapper.findComponent(GlPopover).props().target).toBe(popoverTarget);
    });

    it('passes the issue data into the issue components correctly', () => {
      const issueProps = wrapper
        .findAllComponents(CodequalityIssueBody)
        .wrappers.map((w) => w.props());

      expect(issueProps).toHaveLength(3);
      expect(issueProps).toEqual(
        multipleFindings.codequality.map((codequality) => ({
          issue: {
            severity: codequality.severity,
            name: codequality.description,
          },
          status: 'neutral',
        })),
      );
    });
  });
});

describe('EE CodeQualityGutterIcon with flag on', () => {
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
    createComponent({ codequality: [{ severity }] });

    expect(findIcon().exists()).toBe(true);
    expect(findIcon().attributes()).toMatchObject({
      class: expect.stringContaining(SEVERITY_CLASSES[severity]),
      name: SEVERITY_ICONS[severity],
      size: '12',
    });
  });

  describe('code quality gutter icon', () => {
    describe('with multiple findings', () => {
      beforeEach(() => {
        createComponent(multipleFindings, true);
      });

      it('contains a tooltip', () => {
        expect(containsATooltip(wrapper)).toBe(true);
      });

      it('displays correct popover text with multiple codequality findings', () => {
        expect(wrapper.findComponent(GlTooltip).text()).toContain('3 Code quality findings');
      });

      it('emits showCodeQualityFindings event on click', () => {
        wrapper.trigger('click');
        expect(wrapper.emitted('showCodeQualityFindings').length).toBe(1);
      });
    });
    describe('with singular finding', () => {
      beforeEach(() => {
        createComponent(singularFinding, true);
      });

      it('displays correct popover text with multiple codequality findings', () => {
        expect(wrapper.findComponent(GlTooltip).text()).toContain('1 Code quality finding');
      });
    });
    afterEach(() => {
      wrapper.destroy();
    });
  });
});
