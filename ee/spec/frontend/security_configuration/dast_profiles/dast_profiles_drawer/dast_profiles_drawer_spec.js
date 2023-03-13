import { GlDrawer, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DastProfilesDrawer from 'ee/security_configuration/dast_profiles/dast_profiles_drawer/dast_profiles_drawer.vue';
import DastProfilesLoader from 'ee/security_configuration/dast_profiles/components/dast_profiles_loader.vue';
import {
  scannerProfiles,
  mockSharedData,
} from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';
import resolvers from 'ee/vue_shared/security_configuration/graphql/resolvers/resolvers';
import { SCANNER_TYPE, DRAWER_VIEW_MODE } from 'ee/on_demand_scans/constants';
import { createMockApolloProvider } from '../graphql/create_mock_apollo_provider';

describe('DastProfilesDrawer', () => {
  let wrapper;
  const projectPath = 'projectPath';
  const libraryLink = 'libraryLink';

  const createComponent = (options = {}) => {
    wrapper = mountExtended(DastProfilesDrawer, {
      apolloProvider: createMockApolloProvider(),
      propsData: {
        ...options,
      },
      stubs: {
        GlDrawer: true,
        GlModal: true,
      },
      provide: {
        projectPath,
      },
    });
  };

  const findProfileNameInput = () => wrapper.findByTestId('profile-name-input');
  const findModal = () => wrapper.findByTestId('dast-profile-form-cancel-modal');
  const findEditButton = () => wrapper.findByTestId('profile-edit-btn');
  const findDrawerHeader = () => wrapper.findByTestId('drawer-header');
  const findEmptyStateHeader = () => wrapper.findByTestId('empty-state-header');
  const findNewScanButton = () => wrapper.findByTestId('new-profile-button');
  const findFooterLink = () => wrapper.findComponent(GlLink);
  const findEmptyNewScanButton = () => wrapper.findByTestId('new-empty-profile-button');
  const findNewDastScannerProfileForm = () => wrapper.findByTestId('dast-scanner-parent-group');
  const findCancelButton = () => wrapper.findByTestId('dast-profile-form-cancel-button');
  const findSkeletonLoader = () => wrapper.findComponent(DastProfilesLoader);
  const findGlDrawer = () => wrapper.findComponent(GlDrawer);

  const openEditForm = async () => {
    findEditButton().vm.$emit('click');
    await waitForPromises();
  };

  afterEach(() => {
    mockSharedData.history = [];
  });

  it('should render empty state', async () => {
    createComponent();

    await waitForPromises();

    expect(findEmptyStateHeader().exists()).toBe(true);
    expect(findEmptyStateHeader().text()).toContain(`No ${SCANNER_TYPE} profiles found for DAST`);
    expect(findDrawerHeader().text()).toContain('Scanner profile library');
  });

  it('should render new scan button when profiles exists', async () => {
    createComponent({ profiles: scannerProfiles });
    await waitForPromises();
    expect(findNewScanButton().exists()).toBe(true);
  });

  it('should hide new scan button when no profiles exists', async () => {
    createComponent();
    await waitForPromises();
    expect(findNewScanButton().exists()).toBe(false);
  });

  describe('new profile form', () => {
    it('should emit correct event', async () => {
      createComponent();
      await waitForPromises();

      findEmptyNewScanButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted()).toEqual({
        'reopen-drawer': [[{ mode: DRAWER_VIEW_MODE.EDITING_MODE, profileType: SCANNER_TYPE }]],
      });
      expect(findNewScanButton().exists()).toBe(false);
    });

    it('should close form when cancelled', async () => {
      createComponent({ profiles: scannerProfiles });
      await waitForPromises();

      await openEditForm();

      findCancelButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted()['close-drawer']).toHaveLength(1);
    });
  });

  describe('loading state', () => {
    it('should show loaders when loading is in progress', () => {
      createComponent({ isLoading: true });
      expect(findSkeletonLoader().exists()).toBe(true);
    });
  });

  describe('editing mode', () => {
    it('should be possible to edit profile', async () => {
      createComponent({
        profiles: scannerProfiles,
      });
      await waitForPromises();

      await openEditForm();

      expect(findNewDastScannerProfileForm().exists()).toBe(true);
      expect(findNewScanButton().exists()).toBe(false);
      expect(findDrawerHeader().text()).toContain('Edit scanner profile');
    });
  });

  describe('sticky header', () => {
    it('should have sticky header always enabled', async () => {
      createComponent();
      await waitForPromises();

      expect(findGlDrawer().props('headerSticky')).toBe(true);
    });
  });

  describe('sticky footer', () => {
    it('renders correctly', async () => {
      createComponent({ libraryLink });
      await waitForPromises();

      expect(findFooterLink().text()).toBe(__(`Manage ${SCANNER_TYPE} profiles`));
      expect(findFooterLink().attributes('href')).toEqual(libraryLink);
    });

    it('should have footer in reading mode', async () => {
      createComponent({ profiles: scannerProfiles, libraryLink });
      await waitForPromises();

      expect(findFooterLink().exists()).toBe(true);
    });

    it('should have footer hidden in editing mode', async () => {
      createComponent({ profiles: scannerProfiles, libraryLink });
      await waitForPromises();

      await openEditForm();

      expect(findFooterLink().exists()).toBe(false);
    });
  });

  describe('warning modal', () => {
    it('should show modal on cancel if there are unsaved changes', async () => {
      const showModalMock = jest.spyOn(resolvers.Mutation, 'toggleModal');
      createComponent({ profiles: scannerProfiles });
      await waitForPromises();

      await openEditForm();

      findProfileNameInput().vm.$emit('input', 'another value');
      await waitForPromises();

      findCancelButton().vm.$emit('click');
      await waitForPromises();

      expect(findModal().attributes('visible')).toEqual(String(true));
      expect(showModalMock).toHaveBeenCalledTimes(1);
    });

    it('should show modal before closing drawer if there are unsaved changes', async () => {
      const showModalMock = jest.spyOn(resolvers.Mutation, 'toggleModal');
      createComponent({ profiles: scannerProfiles });
      await waitForPromises();

      await openEditForm();

      findProfileNameInput().vm.$emit('input', 'another value');
      await waitForPromises();

      findGlDrawer().vm.$emit('close');
      await waitForPromises();

      expect(findModal().attributes('visible')).toEqual(String(true));
      expect(showModalMock).toHaveBeenCalledTimes(1);
    });

    it('should reset state history and close drawer if there are no unsaved changes', async () => {
      const resetHistoryMock = jest.spyOn(resolvers.Mutation, 'resetHistory');
      createComponent({ profiles: scannerProfiles });
      await waitForPromises();

      findGlDrawer().vm.$emit('close');
      await waitForPromises();

      expect(resetHistoryMock).toHaveBeenCalledTimes(1);
      expect(wrapper.emitted()['close-drawer']).toHaveLength(1);
    });

    it('should discard changes from warning modal', async () => {
      const goBackMock = jest.spyOn(resolvers.Mutation, 'goBack');
      const setCachedPayloadMock = jest.spyOn(resolvers.Mutation, 'setCachedPayload');
      createComponent({ profiles: scannerProfiles });
      await waitForPromises();

      await openEditForm();

      findProfileNameInput().vm.$emit('input', 'another value');
      await waitForPromises();

      findGlDrawer().vm.$emit('close');
      await waitForPromises();

      findModal().vm.$emit('primary');
      await waitForPromises();

      expect(findModal().exists()).toBe(false);
      expect(goBackMock).toHaveBeenCalledTimes(1);
      expect(setCachedPayloadMock).toHaveBeenCalledTimes(1);
      expect(wrapper.emitted()['close-drawer']).toHaveLength(2);
    });
  });
});
