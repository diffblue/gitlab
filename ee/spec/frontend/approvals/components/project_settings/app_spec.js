import { shallowMount } from '@vue/test-utils';
import App from 'ee/approvals/components/project_settings/app.vue';
import ParentLevelApp from 'ee/approvals/components/app.vue';
import ScanResultPolicies from 'ee/approvals/components/security_orchestration/scan_result_policies.vue';
import ProjectApprovalSettings from 'ee/approvals/components/project_settings/project_approval_settings.vue';

describe('Approvals ProjectSettings App', () => {
  let wrapper;

  const findApp = () => wrapper.findComponent(ParentLevelApp);
  const findScanResultPolicies = () => wrapper.findComponent(ScanResultPolicies);
  const findProjectApprovalSettings = () => wrapper.findComponent(ProjectApprovalSettings);

  const factory = (glFeatures = {}) => {
    wrapper = shallowMount(App, {
      provide: {
        glFeatures: {
          securityOrchestrationPolicies: true,
          ...glFeatures,
        },
      },
    });
  };

  beforeEach(() => {
    factory();
  });

  describe('initial state', () => {
    it('renders all the main components', () => {
      expect(findApp().exists()).toBe(true);
      expect(findScanResultPolicies().exists()).toBe(true);
      expect(findProjectApprovalSettings().exists()).toBe(true);
    });

    describe('without licensed feature securityOrchestrationPolicies', () => {
      beforeEach(() => {
        factory({ securityOrchestrationPolicies: false });
      });

      it('renders all but the scan result policies component', () => {
        expect(findApp().exists()).toBe(true);
        expect(findScanResultPolicies().exists()).toBe(false);
        expect(findProjectApprovalSettings().exists()).toBe(true);
      });
    });
  });
});
