import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { GlAlert, GlCollapsibleListbox, GlFormInput, GlAvatar } from '@gitlab/ui';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'helpers/test_constants';
import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import { ACCESS_LEVELS } from 'ee/protected_environments/constants';
import CreateProtectedEnvironment from 'ee/protected_environments/create_protected_environment.vue';
import httpStatusCodes, { HTTP_STATUS_BAD_REQUEST } from '~/lib/utils/http_status';
import { __, s__ } from '~/locale';

const SEARCH_URL = '/search';
const PROJECT_ID = '0';

describe('ee/protected_environments/create_protected_environment.vue', () => {
  const unmockLocation = useMockLocationHelper();

  let wrapper;
  let originalGon;
  let mockAxios;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEnvironmentsListbox = () =>
    wrapper.findByTestId('create-environment').findComponent(GlCollapsibleListbox);
  const findAccessDropdown = () =>
    wrapper.findByTestId('create-deployer-dropdown').findComponent(AccessDropdown);
  const findRequiredCountSelect = () =>
    wrapper.findByTestId('create-approval-count').findComponent(GlCollapsibleListbox);
  const findRequredCountForApprover = (name) =>
    wrapper
      .findAllComponents(GlFormInput)
      .wrappers.find((w) => w.attributes('name') === `approval-count-${name}`);
  const findApproverDropdown = () =>
    wrapper.findByTestId('create-approver-dropdown').findComponent(AccessDropdown);
  const findSubmitButton = () =>
    wrapper.findByRole('button', { name: s__('ProtectedEnvironment|Protect') });

  beforeEach(() => {
    originalGon = window.gon;

    window.gon = {
      ...window.gon,
      api_version: 'v4',
      deploy_access_levels: {
        roles: [],
      },
    };
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    window.gon = originalGon;
    mockAxios.restore();
  });

  const createComponentWithFeatures = (glFeatures = {}) => ({
    searchUnprotectedEnvironmentsUrl = SEARCH_URL,
    projectId = PROJECT_ID,
  } = {}) => {
    wrapper = mountExtended(CreateProtectedEnvironment, {
      propsData: {
        searchUnprotectedEnvironmentsUrl,
        projectId,
      },
      provide: {
        glFeatures,
        accessLevelsData: [
          {
            id: 40,
            text: 'Maintainers',
            before_divider: true,
          },
          {
            id: 30,
            text: 'Developers + Maintainers',
            before_divider: true,
          },
        ],
      },
    });
  };

  describe('with unified approval rules', () => {
    const createComponent = createComponentWithFeatures();

    const submitForm = async (
      deployAccessLevels = [{ user_id: 1 }],
      name = 'production',
      requiredApprovalCount = '3',
    ) => {
      findAccessDropdown().vm.$emit('hidden', deployAccessLevels);
      findEnvironmentsListbox().vm.$emit('select', name);
      findRequiredCountSelect().vm.$emit('select', requiredApprovalCount);
      await findSubmitButton().vm.$emit('click');
    };

    it('renders AccessDropdown and passes down the props', () => {
      createComponent();
      const dropdown = findAccessDropdown();

      expect(dropdown.props()).toMatchObject({
        accessLevel: ACCESS_LEVELS.DEPLOY,
        label: __('Select users'),
      });
    });

    it('searchs the environment name', async () => {
      const query = 'staging';
      createComponent();

      mockAxios.onGet(SEARCH_URL, { params: { query } }).reply(httpStatusCodes.OK, [query]);

      const environmentSearch = findEnvironmentsListbox();
      environmentSearch.vm.$emit('search', query);

      await waitForPromises();
      await nextTick();

      expect(environmentSearch.props('items')).toEqual([{ value: query, text: query }]);
    });

    it('renders a select for the required approval count', () => {
      createComponent();

      const count = findRequiredCountSelect();

      expect(count.props('toggleText')).toBe('0');
    });

    it('should make a request when submit is clicked', async () => {
      createComponent();

      jest.spyOn(Api, 'createProtectedEnvironment');
      const deployAccessLevels = [{ user_id: 1 }];
      const name = 'production';
      const requiredApprovalCount = '3';

      await submitForm(deployAccessLevels, name, requiredApprovalCount);

      expect(Api.createProtectedEnvironment).toHaveBeenCalledWith(PROJECT_ID, {
        deploy_access_levels: deployAccessLevels,
        required_approval_count: requiredApprovalCount,
        name,
      });
    });

    describe('on successful protected environment', () => {
      it('should reload the page', async () => {
        createComponent();
        mockAxios.onPost().replyOnce(httpStatusCodes.OK);
        await submitForm();
        await waitForPromises();

        expect(window.location.reload).toHaveBeenCalled();
      });
    });

    describe('on failed protected environment', () => {
      it('should show an error message', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_BAD_REQUEST, {});
        createComponent();
        await submitForm();
        await waitForPromises();

        expect(findAlert().text()).toBe(__('Failed to protect the environment'));

        expect(window.location.reload).not.toHaveBeenCalled();
      });
    });
  });

  describe('with multiple approval rules', () => {
    const createComponent = createComponentWithFeatures({
      multipleEnvironmentApprovalRulesFe: true,
    });
    const submitForm = async (
      deployAccessLevels = [{ user_id: 1 }],
      name = 'production',
      requiredApprovalCount = '3',
    ) => {
      mockAxios.onGet('/api/v4/users/1').reply(httpStatusCodes.OK, {
        name: 'root',
        web_url: '/root',
        avatar_url: '/root.png',
        id: 1,
      });
      findAccessDropdown().vm.$emit('hidden', deployAccessLevels);
      findEnvironmentsListbox().vm.$emit('select', name);
      findApproverDropdown().vm.$emit('hidden', deployAccessLevels);
      await waitForPromises();
      findRequredCountForApprover('root').vm.$emit('input', requiredApprovalCount);
      await findSubmitButton().vm.$emit('click');
    };

    it('renders AccessDropdown and passes down the props', () => {
      createComponent();
      const dropdown = findAccessDropdown();

      expect(dropdown.props()).toMatchObject({
        accessLevel: ACCESS_LEVELS.DEPLOY,
        label: __('Select users'),
      });
    });

    it('searchs the environment name', async () => {
      const query = 'staging';
      createComponent();

      mockAxios.onGet(SEARCH_URL, { params: { query } }).reply(httpStatusCodes.OK, [query]);

      const environmentSearch = findEnvironmentsListbox();
      environmentSearch.vm.$emit('search', query);

      await waitForPromises();
      await nextTick();

      expect(environmentSearch.props('items')).toEqual([{ value: query, text: query }]);
    });

    it('renders a dropdown for selecting approvers', () => {
      createComponent();

      const approvers = findApproverDropdown();

      expect(approvers.props()).toMatchObject({
        accessLevel: ACCESS_LEVELS.DEPLOY,
        label: __('Select users'),
      });
    });

    it('should make a request when submit is clicked', async () => {
      createComponent();

      jest.spyOn(Api, 'createProtectedEnvironment');
      const deployAccessLevels = [{ user_id: 1 }];
      const name = 'production';
      const requiredApprovalCount = '3';

      await submitForm(deployAccessLevels, name, requiredApprovalCount);

      expect(Api.createProtectedEnvironment).toHaveBeenCalledWith(PROJECT_ID, {
        deploy_access_levels: deployAccessLevels,
        approval_rules: [{ user_id: 1, required_approvals: '3' }],
        name,
      });
    });

    describe('on successful protected environment', () => {
      it('should reload the page', async () => {
        createComponent();
        mockAxios.onPost().replyOnce(httpStatusCodes.OK);
        await submitForm();
        await waitForPromises();

        expect(window.location.reload).toHaveBeenCalled();
      });
    });

    describe('on failed protected environment', () => {
      it('should show an error message', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_BAD_REQUEST, {});
        createComponent();
        await submitForm();
        await waitForPromises();

        expect(findAlert().text()).toBe(__('Failed to protect the environment'));

        expect(window.location.reload).not.toHaveBeenCalled();
      });
    });

    describe('information for approvers', () => {
      unmockLocation();
      beforeEach(() => {
        mockAxios.onGet('/api/v4/users/1').replyOnce(httpStatusCodes.OK, {
          name: 'root',
          web_url: `${TEST_HOST}/root`,
          avatar_url: '/root.png',
          id: 1,
        });
        mockAxios.onGet('/api/v4/groups/1').replyOnce(httpStatusCodes.OK, {
          full_name: 'root / group',
          name: 'group',
          web_url: `${TEST_HOST}/root/group`,
          avatar_url: '/root/group.png',
          id: 1,
        });
      });

      describe.each`
        type              | access                  | details
        ${'access level'} | ${{ access_level: 30 }} | ${{ name: 'Developers + Maintainers' }}
        ${'group'}        | ${{ group_id: 1 }}      | ${{ avatarUrl: '/root/group.png', href: `${TEST_HOST}/root/group`, name: 'root / group' }}
        ${'user'}         | ${{ user_id: 1 }}       | ${{ avatarUrl: '/root.png', href: `${TEST_HOST}/root`, name: 'root', inputDisabled: true }}
      `('it displays correct information for $type', ({ access, details }) => {
        beforeEach(async () => {
          createComponent();
          findEnvironmentsListbox().vm.$emit('select', 'production');
          findApproverDropdown().vm.$emit('hidden', [access]);
          await waitForPromises();
          await nextTick();
        });

        if (details.href) {
          it('should link to the entity', () => {
            const link = wrapper.findByRole('link', { name: details.name });
            expect(link.attributes('href')).toBe(details.href);
          });
        } else {
          it('should display the name of the entity', () => {
            expect(wrapper.text()).toContain(details.name);
          });
        }

        if (details.avatarUrl) {
          it('should show an avatar', () => {
            const avatar = wrapper.findComponent(GlAvatar);
            expect(avatar.props('src')).toBe(details.avatarUrl);
          });
        }

        if (details.inputDisabled) {
          it('should have the input disabled and set to 1', () => {
            const input = findRequredCountForApprover(details.name);
            expect(input.element.value).toBe('1');
            expect(input.attributes('disabled')).toBeDefined();
          });
        } else {
          it('should not have the input disabled and set to 0', () => {
            const input = findRequredCountForApprover(details.name);
            expect(input.element.value).toBe('1');
            expect(input.attributes('disabled')).toBeUndefined();
          });
        }
      });
    });
  });
});
