import { GlSprintf } from '@gitlab/ui';
import ScanTypeSelect from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_type_select.vue';
import AnyMergeRequestRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result/rule/any_merge_request_rule_builder.vue';
import BranchExceptionSelector from 'ee/security_orchestration/components/policy_editor/branch_exception_selector.vue';
import SectionLayout from 'ee/security_orchestration/components/policy_editor/section_layout.vue';
import BranchSelection from 'ee/security_orchestration/components/policy_editor/scan_result/rule/branch_selection.vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  ANY_COMMIT,
  ANY_UNSIGNED_COMMIT,
  PROJECT_DEFAULT_BRANCH,
} from 'ee/security_orchestration/components/policy_editor/constants';
import {
  ANY_MERGE_REQUEST,
  getDefaultRule,
  anyMergeRequestBuildRule,
  SCAN_FINDING,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib/rules';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

describe('AnyMergeRequestRuleBuilder', () => {
  let wrapper;

  const UPDATED_RULE = {
    ...anyMergeRequestBuildRule(),
    branch_type: PROJECT_DEFAULT_BRANCH.value,
    commits: ANY_UNSIGNED_COMMIT,
  };

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(AnyMergeRequestRuleBuilder, {
      propsData: {
        initRule: anyMergeRequestBuildRule(),
        ...props,
      },
      provide: {
        namespaceType: NAMESPACE_TYPES.GROUP,
        glFeatures: {
          securityPoliciesBranchExceptions: true,
        },
        ...provide,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findAllBaseLayoutComponent = () => wrapper.findAllComponents(SectionLayout);
  const findCommitsTypeListBox = () => wrapper.findByTestId('commits-type');
  const findScanTypeSelect = () => wrapper.findComponent(ScanTypeSelect);
  const findBranches = () => wrapper.findComponent(BranchSelection);
  const findBranchExceptionSelector = () => wrapper.findComponent(BranchExceptionSelector);

  describe('initial rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders one field for each attribute of the rule', () => {
      expect(findScanTypeSelect().exists()).toBe(true);
      expect(findBranches().exists()).toBe(true);
      expect(findCommitsTypeListBox().exists()).toBe(true);
    });

    it('can remove rule builder', () => {
      findAllBaseLayoutComponent().at(1).vm.$emit('remove');
      expect(wrapper.emitted('remove')).toHaveLength(1);
    });

    it('can change scan type', () => {
      findScanTypeSelect().vm.$emit('select', SCAN_FINDING);

      expect(wrapper.emitted('set-scan-type')).toEqual([[getDefaultRule(SCAN_FINDING)]]);
    });

    it('can change branch_type', () => {
      findBranches().vm.$emit('set-branch-type', UPDATED_RULE);

      expect(wrapper.emitted('changed')).toEqual([[UPDATED_RULE]]);
    });

    it('can change commits type', () => {
      expect(findCommitsTypeListBox().props('selected')).toBe(ANY_COMMIT);
      findCommitsTypeListBox().vm.$emit('select', ANY_UNSIGNED_COMMIT);

      expect(wrapper.emitted('changed')).toEqual([
        [
          {
            ...getDefaultRule(ANY_MERGE_REQUEST),
            commits: ANY_UNSIGNED_COMMIT,
          },
        ],
      ]);
    });
  });

  it('should display saved rule parameters', () => {
    createComponent({
      props: {
        initRule: {
          ...UPDATED_RULE,
        },
      },
    });

    expect(findBranches().props('initRule')).toEqual(UPDATED_RULE);

    expect(findCommitsTypeListBox().props('selected')).toBe(UPDATED_RULE.commits);

    expect(findScanTypeSelect().props('scanType')).toBe(ANY_MERGE_REQUEST);
  });

  describe('adding branch exceptions', () => {
    const exceptions = { branch_exceptions: ['main', 'test'] };

    it.each`
      namespaceType              | expectedResult
      ${NAMESPACE_TYPES.PROJECT} | ${true}
      ${NAMESPACE_TYPES.GROUP}   | ${false}
    `('should select exceptions only on project level', ({ namespaceType, expectedResult }) => {
      createComponent({
        provide: {
          namespaceType,
        },
      });

      expect(findBranchExceptionSelector().exists()).toBe(expectedResult);
    });

    it('should select exceptions', () => {
      createComponent({
        provide: {
          namespaceType: NAMESPACE_TYPES.PROJECT,
        },
      });

      findBranchExceptionSelector().vm.$emit('select', exceptions);

      expect(wrapper.emitted('changed')).toEqual([
        [
          {
            ...anyMergeRequestBuildRule(),
            ...exceptions,
          },
        ],
      ]);
    });

    it('should display saved exceptions', () => {
      createComponent({
        props: {
          initRule: {
            ...anyMergeRequestBuildRule(),
            ...exceptions,
          },
        },
        provide: {
          namespaceType: NAMESPACE_TYPES.PROJECT,
        },
      });

      expect(findBranchExceptionSelector().props('selectedExceptions')).toEqual(
        exceptions.branch_exceptions,
      );
    });

    it('should remove selection from rule', () => {
      createComponent({
        props: {
          initRule: {
            ...anyMergeRequestBuildRule(),
            ...exceptions,
          },
        },
        provide: {
          namespaceType: NAMESPACE_TYPES.PROJECT,
        },
      });

      findBranchExceptionSelector().vm.$emit('remove');

      expect(wrapper.emitted('changed')).toEqual([
        [
          {
            ...anyMergeRequestBuildRule(),
          },
        ],
      ]);
    });
  });
});
