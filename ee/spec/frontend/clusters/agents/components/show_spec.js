import { GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
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

  const createWrapper = ({ glFeatures = {} } = {}) => {
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

  afterEach(() => {
    wrapper.destroy();
  });

  describe('tab behavior', () => {
    it.each`
      title                                                                                                                      | glFeatures                                                                  | tabStatus
      ${'does not display the tab when no glFeatures are available'}                                                             | ${{}}                                                                       | ${false}
      ${'does not display the tab when only the "clusterVulnerabilities" flag is true'}                                          | ${{ clusterVulnerabilities: true }}                                         | ${false}
      ${'does not display the tab when only the "kubernetesClusterVulnerabilities" flag is true'}                                | ${{ kubernetesClusterVulnerabilities: true }}                               | ${false}
      ${'does display the tab when both the "kubernetesClusterVulnerabilities" flag and "clusterVulnerabilities" flag are true'} | ${{ clusterVulnerabilities: true, kubernetesClusterVulnerabilities: true }} | ${true}
    `('$title', async ({ glFeatures, tabStatus }) => {
      createWrapper({ glFeatures });
      await nextTick();
      expect(findTab().exists()).toBe(tabStatus);
    });
  });

  describe('vulnerability report', () => {
    it('renders with cluster agent id', async () => {
      createWrapper({
        glFeatures: { clusterVulnerabilities: true, kubernetesClusterVulnerabilities: true },
      });
      await nextTick();
      expect(findAgentVulnerabilityReport().props('clusterAgentId')).toBe(clusterAgentId);
    });
  });
});
