import { GlDeprecatedSkeletonLoading as GlSkeletonLoading } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import UnconfiguredSecurityRule from 'ee/approvals/components/security_configuration/unconfigured_security_rule.vue';
import UnconfiguredSecurityRules from 'ee/approvals/components/security_configuration/unconfigured_security_rules.vue';
import { createStoreOptions } from 'ee/approvals/stores';
import projectSettingsModule from 'ee/approvals/stores/modules/project_settings';

Vue.use(Vuex);

describe('UnconfiguredSecurityRules component', () => {
  let wrapper;
  let store;

  const TEST_PROJECT_ID = '7';

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(UnconfiguredSecurityRules, {
      store,
      propsData: {
        ...props,
      },
      provide: {
        vulnerabilityCheckHelpPagePath: '',
        licenseCheckHelpPagePath: '',
      },
    });
  };

  beforeEach(() => {
    store = new Vuex.Store(
      createStoreOptions({ approvals: projectSettingsModule() }, { projectId: TEST_PROJECT_ID }),
    );
    jest.spyOn(store, 'dispatch');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when created ', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should fetch the security configuration', () => {
      expect(store.dispatch).toHaveBeenCalledWith(
        'securityConfiguration/fetchSecurityConfiguration',
        undefined,
      );
    });

    it('should render a unconfigured-security-rule component for every security rule ', () => {
      expect(wrapper.findAllComponents(UnconfiguredSecurityRule).length).toBe(3);
    });
  });

  describe.each`
    approvalsLoading | securityConfigurationLoading | shouldRender
    ${false}         | ${false}                     | ${false}
    ${true}          | ${false}                     | ${true}
    ${false}         | ${true}                      | ${true}
    ${true}          | ${true}                      | ${true}
  `(
    'while approvalsLoading is $approvalsLoading and securityConfigurationLoading is $securityConfigurationLoading',
    ({ approvalsLoading, securityConfigurationLoading, shouldRender }) => {
      beforeEach(() => {
        createWrapper();
        store.state.approvals.isLoading = approvalsLoading;
        store.state.securityConfiguration.isLoading = securityConfigurationLoading;
      });

      it(`should ${shouldRender ? '' : 'not'} render the loading skeleton`, () => {
        expect(wrapper.findComponent(GlSkeletonLoading).exists()).toBe(shouldRender);
      });
    },
  );
});
