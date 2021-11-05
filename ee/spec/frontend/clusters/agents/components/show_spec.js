import { GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ClusterAgentShow from 'ee/clusters/agents/components/show.vue';
import CEClusterAgentShowPage from '~/clusters/agents/components/show.vue';

describe('ClusterAgentShow', () => {
  let wrapper;
  const agentName = 'best-agent';
  const projectPath = 'path/to/project';

  const createWrapper = ({ glFeatures = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(ClusterAgentShow, {
        propsData: { agentName, projectPath },
        provide: { glFeatures },
      }),
    );
  };

  const findTab = () => wrapper.findComponent(GlTab);
  const findCEClusterAgentShowPage = () => wrapper.findComponent(CEClusterAgentShowPage);

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
      expect(findCEClusterAgentShowPage().props()).toStrictEqual({ agentName, projectPath });
      expect(findTab().exists()).toBe(tabStatus);
    });
  });
});
