import { GlPath } from '@gitlab/ui';
import * as urlUtils from '~/lib/utils/url_utility';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/security_orchestration/components/constants';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import App from 'ee/security_orchestration/components/policy_editor/app.vue';
import PolicyTypeSelector from 'ee/security_orchestration/components/policy_editor/policy_type_selector.vue';
import EditorWrapper from 'ee/security_orchestration/components/policy_editor/editor_wrapper.vue';

describe('App component', () => {
  let wrapper;

  const findPolicySelection = () => wrapper.findComponent(PolicyTypeSelector);
  const findPolicyEditor = () => wrapper.findComponent(EditorWrapper);
  const findPath = () => wrapper.findComponent(GlPath);

  const factory = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(App, {
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
        expect(wrapper.findByText(App.i18n.titles.default).exists()).toBe(true);
      });

      it('should display the path items correctly', () => {
        expect(findPath().props('items')).toMatchObject([
          {
            selected: true,
            title: App.i18n.choosePolicyType,
          },
          {
            disabled: true,
            selected: false,
            title: App.i18n.policyDetails,
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
        expect(wrapper.findByText(App.i18n.titles.default).exists()).toBe(true);
      });

      it('should display the correct view', () => {
        expect(findPolicySelection().exists()).toBe(true);
        expect(findPolicyEditor().exists()).toBe(false);
      });

      it('should display the path items correctly', () => {
        expect(findPath().props('items')).toMatchObject([
          {
            selected: true,
            title: App.i18n.choosePolicyType,
          },
          {
            disabled: true,
            selected: false,
            title: App.i18n.policyDetails,
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
      expect(wrapper.findByText(App.i18n.editTitles.scanResult).exists()).toBe(true);
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
