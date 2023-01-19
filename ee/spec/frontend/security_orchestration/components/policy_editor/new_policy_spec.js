import { GlPath } from '@gitlab/ui';
import * as urlUtils from '~/lib/utils/url_utility';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/security_orchestration/components/constants';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import NewPolicy from 'ee/security_orchestration/components/policy_editor/new_policy.vue';
import PolicySelection from 'ee/security_orchestration/components/policy_editor/policy_selection.vue';
import PolicyEditor from 'ee/security_orchestration/components/policy_editor/policy_editor.vue';

describe('NewPolicy component', () => {
  let wrapper;

  const findPolicySelection = () => wrapper.findComponent(PolicySelection);
  const findPolicyEditor = () => wrapper.findComponent(PolicyEditor);
  const findPath = () => wrapper.findComponent(GlPath);

  const factory = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(NewPolicy, {
      provide: {
        assignedPolicyProject: {},
        namespaceType: NAMESPACE_TYPES.GROUP,
        ...provide,
      },
      stubs: { GlPath: true },
    });
  };

  describe('when there is no type query parameter', () => {
    describe('projects', () => {
      beforeEach(() => {
        factory({ provide: { namespaceType: NAMESPACE_TYPES.PROJECT } });
      });

      it('should display the title correctly', () => {
        expect(wrapper.findByText(NewPolicy.i18n.titles.default).exists()).toBe(true);
      });

      it('should display the path items correctly', () => {
        expect(findPath().props('items')).toMatchObject([
          {
            selected: true,
            title: NewPolicy.i18n.choosePolicyType,
          },
          {
            disabled: true,
            selected: false,
            title: NewPolicy.i18n.policyDetails,
          },
        ]);
      });

      it('should display the correct view', () => {
        expect(findPolicySelection().exists()).toBe(true);
        expect(findPolicyEditor().exists()).toBe(false);
      });
    });

    describe('groups', () => {
      beforeEach(() => {
        factory({ provide: { namespaceType: NAMESPACE_TYPES.GROUP } });
      });

      it('should display the title correctly', () => {
        expect(wrapper.findByText(NewPolicy.i18n.titles.default).exists()).toBe(true);
      });

      it('should display the correct view', () => {
        expect(findPolicySelection().exists()).toBe(true);
        expect(findPolicyEditor().exists()).toBe(false);
      });

      it('should display the path items correctly', () => {
        expect(findPath().props('items')).toMatchObject([
          {
            selected: true,
            title: NewPolicy.i18n.choosePolicyType,
          },
          {
            disabled: true,
            selected: false,
            title: NewPolicy.i18n.policyDetails,
          },
        ]);
      });
    });
  });

  describe('when there is a type query parameter', () => {
    beforeEach(() => {
      jest
        .spyOn(urlUtils, 'getParameterByName')
        .mockReturnValue(POLICY_TYPE_COMPONENT_OPTIONS.scanResult.urlParameter);
      factory({
        provide: {
          namespaceType: NAMESPACE_TYPES.PROJECT,
          existingPolicy: {
            id: 'policy-id',
          },
        },
      });
    });

    it('should display the title correctly', () => {
      expect(wrapper.findByText(NewPolicy.i18n.editTitles.scanResult).exists()).toBe(true);
    });

    it('should not display the GlPath component when there is an existing policy', () => {
      expect(findPath().exists()).toBe(false);
    });

    it('should display the correct view according to the selected policy', () => {
      expect(findPolicySelection().exists()).toBe(false);
      expect(findPolicyEditor().exists()).toBe(true);
    });
  });
});
