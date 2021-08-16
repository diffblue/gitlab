import { GlButton, GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import AgentTable from 'ee/clusters_list/components/agent_table.vue';

const propsData = {
  agents: [
    {
      name: 'agent-1',
      configFolder: {
        webPath: '/agent/full/path',
      },
      webPath: '/agent-1',
    },
    {
      name: 'agent-2',
      webPath: '/agent-2',
    },
  ],
};
const provideData = { integrationDocsUrl: 'path/to/integrationDocs' };

describe('AgentTable', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(AgentTable, { propsData, provide: provideData });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  it('displays header button', () => {
    expect(wrapper.find(GlButton).text()).toBe('Install a new GitLab Agent');
  });

  describe('agent table', () => {
    it.each`
      agentName    | link          | lineNumber
      ${'agent-1'} | ${'/agent-1'} | ${0}
      ${'agent-2'} | ${'/agent-2'} | ${1}
    `('displays agent link', ({ agentName, link, lineNumber }) => {
      const agents = wrapper.findAll(
        '[data-testid="cluster-agent-list-table"] tbody tr > td:first-child',
      );
      const agent = agents.at(lineNumber).find(GlLink);

      expect(agent.text()).toBe(agentName);
      expect(agent.attributes('href')).toBe(link);
    });

    it.each`
      agentPath                   | hasLink  | lineNumber
      ${'.gitlab/agents/agent-1'} | ${true}  | ${0}
      ${'.gitlab/agents/agent-2'} | ${false} | ${1}
    `('displays config file path', ({ agentPath, hasLink, lineNumber }) => {
      const agents = wrapper.findAll(
        '[data-testid="cluster-agent-list-table"] tbody tr > td:nth-child(2)',
      );
      const agent = agents.at(lineNumber);

      expect(agent.find(GlLink).exists()).toBe(hasLink);
      expect(agent.text()).toBe(agentPath);
    });
  });
});
