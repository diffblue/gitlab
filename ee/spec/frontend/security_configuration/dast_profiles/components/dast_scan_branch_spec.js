import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import profilesFixtures from 'test_fixtures/graphql/on_demand_scans/graphql/dast_profiles.query.graphql.json';
import DastScanBranch from 'ee/security_configuration/dast_profiles/components/dast_scan_branch.vue';

const [
  scanWithInexistingBranch,
  scanWithExistingBranch,
] = profilesFixtures.data.project.pipelines.nodes;

describe('EE - DastSavedScansList', () => {
  let wrapper;

  const createWrapper = (propsData = {}) => {
    wrapper = shallowMount(DastScanBranch, {
      propsData,
    });
  };

  it('renders branch information if it exists', () => {
    const { branch, editPath } = scanWithExistingBranch;
    createWrapper({ branch, editPath });

    expect(wrapper.text()).toContain(branch.name);
    expect(wrapper.findComponent(GlIcon).props('name')).toBe('branch');
  });

  describe('branch does not exist', () => {
    beforeEach(() => {
      const { branch, editPath } = scanWithInexistingBranch;
      createWrapper({ branch, editPath });
    });

    it('renders a warning message', () => {
      expect(wrapper.text()).toContain('Branch missing');
      expect(wrapper.findComponent(GlIcon).props('name')).toBe('warning');
    });

    it('renders the edit link', () => {
      const link = wrapper.findComponent(GlLink);
      expect(link.text()).toBe('Select branch');
      expect(link.attributes('href')).toBe(scanWithInexistingBranch.editPath);
    });
  });
});
