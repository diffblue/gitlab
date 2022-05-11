import { mountExtended } from 'helpers/vue_test_utils_helper';
import DastProfilesSidebar from 'ee/security_configuration/dast_profiles/dast_profiles_sidebar/dast_profiles_sidebar.vue';
import { scannerProfiles } from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';

describe('DastProfilesSidebar', () => {
  let wrapper;
  const createComponent = (options = {}) => {
    wrapper = mountExtended(DastProfilesSidebar, {
      propsData: {
        ...options,
      },
      stubs: {
        GlDrawer: true,
      },
    });
  };

  const findSidebarHeader = () => wrapper.findByTestId('sidebar-header');
  const findEmptyStateHeader = () => wrapper.findByTestId('empty-state-header');
  const findNewScanButton = () => wrapper.findByTestId('new-profile-button');

  afterEach(() => {
    wrapper.destroy();
  });

  it('should show empty state when no scanner profiles exist', () => {
    createComponent({ profileType: 'scanner' });
    expect(findEmptyStateHeader().exists()).toBe(true);
    expect(findEmptyStateHeader().text()).toContain('No scanner profiles found for DAST');
    expect(findSidebarHeader().text()).toContain('Scanner profile library');
  });

  it('should show empty state when no site profiles exist', () => {
    createComponent({ profileType: 'site' });
    expect(findEmptyStateHeader().exists()).toBe(true);
    expect(findEmptyStateHeader().text()).toContain('No site profiles found for DAST');
    expect(findSidebarHeader().text()).toContain('Site profile library');
  });

  it('should render new scan button when profiles exists', () => {
    createComponent({ profiles: scannerProfiles });
    expect(findNewScanButton().exists()).toBe(true);
  });

  it('should hide new scan button when no profiles exists', () => {
    createComponent();
    expect(findNewScanButton().exists()).toBe(false);
  });
});
