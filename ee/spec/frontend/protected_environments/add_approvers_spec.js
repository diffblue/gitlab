import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { GlAvatar, GlFormInput } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import { ACCESS_LEVELS } from 'ee/protected_environments/constants';
import AddApprovers from 'ee/protected_environments/add_approvers.vue';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { __, s__ } from '~/locale';

const PROJECT_ID = '0';

describe('ee/protected_environments/add_approvers.vue', () => {
  let wrapper;
  let mockAxios;

  const createComponent = ({ projectId = PROJECT_ID, disabled = false } = {}) => {
    wrapper = mountExtended(AddApprovers, {
      propsData: {
        projectId,
        disabled,
      },
      provide: {
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

  const findApproverDropdown = () => wrapper.findComponent(AccessDropdown);

  const findRequiredCountForApprover = (name) =>
    wrapper
      .findAllComponents(GlFormInput)
      .wrappers.find((w) => w.attributes('name') === `approval-count-${name}`);

  beforeEach(() => {
    window.gon = {
      api_version: 'v4',
      deploy_access_levels: {
        roles: [],
      },
    };
    mockAxios = new MockAdapter(axios);
  });

  it('renders a dropdown for selecting approvers', () => {
    createComponent();

    const approvers = findApproverDropdown();

    expect(approvers.props()).toMatchObject({
      accessLevel: ACCESS_LEVELS.DEPLOY,
      label: __('Select users'),
    });
  });

  it('emits an error if unable to fetch details for an approver', async () => {
    mockAxios.onGet().replyOnce(HTTP_STATUS_BAD_REQUEST);

    createComponent();
    findApproverDropdown().vm.$emit('hidden', [{ group_id: 1 }]);

    await waitForPromises();

    const [[event]] = wrapper.emitted('error').reverse();
    expect(event).toBe(
      s__(
        'ProtectedEnvironments|An error occurred while fetching information on the selected approvers.',
      ),
    );
  });

  it('emits an empty error value when fetching new details', async () => {
    createComponent();
    findApproverDropdown().vm.$emit('hidden', [{ group_id: 1 }]);

    await waitForPromises();

    mockAxios.onGet('/api/v4/users/1').replyOnce(HTTP_STATUS_OK, {
      name: 'root',
      web_url: `${TEST_HOST}/root`,
      avatar_url: '/root.png',
      id: 1,
    });
    findApproverDropdown().vm.$emit('hidden', [{ user_id: 1 }]);

    await waitForPromises();

    const [[event]] = wrapper.emitted('error').reverse();
    expect(event).toBe('');
  });

  describe('information for approvers', () => {
    beforeEach(() => {
      mockAxios.onGet('/api/v4/users/1').replyOnce(HTTP_STATUS_OK, {
        name: 'root',
        web_url: `${TEST_HOST}/root`,
        avatar_url: '/root.png',
        id: 1,
      });
      mockAxios.onGet('/api/v4/groups/1').replyOnce(HTTP_STATUS_OK, {
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
        findApproverDropdown().vm.$emit('hidden', [access]);
        await nextTick();
        await waitForPromises();
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
          const input = findRequiredCountForApprover(details.name);
          expect(input.element.value).toBe('1');
          expect(input.attributes('disabled')).toBeDefined();
        });
      } else {
        it('should not have the input disabled and set to 1', () => {
          const input = findRequiredCountForApprover(details.name);
          expect(input.element.value).toBe('1');
          expect(input.attributes('disabled')).toBeUndefined();
        });
      }

      it('emits approver info', async () => {
        const input = findRequiredCountForApprover(details.name);
        input.vm.$emit('input', 3);
        await nextTick();
        const [[[event]]] = wrapper.emitted('change').reverse();
        expect(event).toEqual({ ...access, required_approvals: 3 });
      });
    });
  });
});
