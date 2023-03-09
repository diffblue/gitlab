import { GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ClusterAgentShow from 'ee/clusters/agents/components/show.vue';
import AgentShowPage from '~/clusters/agents/components/show.vue';
import AgentVulnerabilityReport from 'ee/security_dashboard/components/agent/agent_vulnerability_report.vue';

describe('ClusterAgentShow', () => {
  let wrapper;

  const clusterAgentId = 'gid://gitlab/Clusters::Agent/1';
  const AgentShowPageStub = stubComponent(AgentShowPage, {
    provide: { agentName: 'test', projectPath: 'test' },
    template: `<div><slot name="ee-security-tab" clusterAgentId="${clusterAgentId}"></slot></div>`,
  });

  const createWrapper = ({ glFeatures = { kubernetesClusterVulnerabilities: true } } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(ClusterAgentShow, {
        provide: { glFeatures },
        stubs: {
          AgentShowPage: AgentShowPageStub,
        },
      }),
    );
  };

  const findAgentVulnerabilityReport = () => wrapper.findComponent(AgentVulnerabilityReport);
  const findTab = () => wrapper.findComponent(GlTab);

  describe('when a user does have permission', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not display the tab', () => {
      expect(findTab().exists()).toBe(true);
    });

    it('does display the cluster agent id', () => {
      expect(findAgentVulnerabilityReport().props('clusterAgentId')).toBe(clusterAgentId);
    });
  });

  describe('without access', () => {
    beforeEach(() => {
      createWrapper({ glFeatures: { kubernetesClusterVulnerabilities: false } });
    });

    it('when a user does not have permission', () => {
      expect(findTab().exists()).toBe(false);
    });
  });
});
