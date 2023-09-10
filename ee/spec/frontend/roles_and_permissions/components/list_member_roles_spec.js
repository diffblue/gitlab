import { GlCard, GlEmptyState, GlModal, GlTable } from '@gitlab/ui';
import { nextTick } from 'vue';
import { createAlert, VARIANT_DANGER } from '~/alert';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { getMemberRoles, deleteMemberRole } from 'ee/api/member_roles_api';
import CreateMemberRole from 'ee/roles_and_permissions/components/create_member_role.vue';
import {
  I18N_CREATION_SUCCESS,
  I18N_DELETION_ERROR,
  I18N_DELETION_SUCCESS,
  I18N_FETCH_ERROR,
  I18N_LICENSE_ERROR,
} from 'ee/roles_and_permissions/constants';
import ListMemberRoles from 'ee/roles_and_permissions/components/list_member_roles.vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('ee/api/member_roles_api');

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

describe('ListMemberRoles', () => {
  const emptyText = 'blah, blah';
  const groupId = '49';
  const mockResponse = [
    {
      id: 1,
      name: 'My custom Guest',
      base_access_level: 10,
      read_code: true,
      read_vulnerability: true,
      admin_vulnerability: true,
    },
    {
      id: 2,
      name: 'My name Developer',
      base_access_level: 30,
      non_standard_permission: true,
      ignored: false,
    },
  ];
  const mockToastShow = jest.fn();
  let wrapper;

  const createComponent = (props = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(ListMemberRoles, {
      propsData: { emptyText, ...props },
      stubs: { GlCard },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const findAddRoleButton = () => wrapper.findByTestId('add-role');
  const findButtonByText = (text) => wrapper.findByRole('button', { name: text });
  const findCounter = () => wrapper.findByTestId('counter');
  const findCreateMemberRole = () => wrapper.findComponent(CreateMemberRole);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findModal = () => wrapper.findComponent(GlModal);
  const findTable = () => wrapper.findComponent(GlTable);
  const findCellByText = (text) => wrapper.findByRole('cell', { name: text });
  const findCells = () => wrapper.findAllByRole('cell');

  beforeEach(() => {
    getMemberRoles.mockResolvedValue({ data: mockResponse });
  });

  it('shows empty state', () => {
    createComponent({ groupId: null });
    expect(wrapper.findByTestId('card-title').text()).toMatch(ListMemberRoles.i18n.cardTitle);
    expect(findCounter().text()).toBe('0');
    expect(findAddRoleButton().props('disabled')).toBe(true);
    expect(findEmptyState().props()).toMatchObject({
      description: emptyText,
      title: ListMemberRoles.i18n.emptyTitle,
    });
    expect(findCreateMemberRole().exists()).toBe(false);
  });

  describe('fetching roles', () => {
    it('toggles the table busy state', async () => {
      createComponent({ groupId });
      await waitForPromises();
      expect(findTable().attributes('busy')).toBeUndefined();

      wrapper.setProps({ groupId: '9' });
      await nextTick();
      expect(findTable().attributes('busy')).toBe('true');
    });

    it('upon changes in the groupId', async () => {
      createComponent({ groupId: null });
      await waitForPromises();
      expect(getMemberRoles).toHaveBeenCalledTimes(0);

      wrapper.setProps({ groupId });
      await waitForPromises();
      expect(getMemberRoles).toHaveBeenCalledTimes(1);
    });

    it('shows license alert for 404 responses', async () => {
      getMemberRoles.mockRejectedValue({ response: { status: HTTP_STATUS_NOT_FOUND } });
      createComponent({ groupId: '100' });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: I18N_LICENSE_ERROR,
        variant: VARIANT_DANGER,
      });
    });

    it('shows generic alert for non-404 responses', async () => {
      getMemberRoles.mockRejectedValue({ response: { status: HTTP_STATUS_INTERNAL_SERVER_ERROR } });
      createComponent({ groupId: '100' });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: I18N_FETCH_ERROR,
        variant: VARIANT_DANGER,
      });
    });

    it('dismisses previous alerts', async () => {
      getMemberRoles.mockRejectedValue({ response: { status: HTTP_STATUS_INTERNAL_SERVER_ERROR } });
      createComponent({ groupId: '100' });
      await waitForPromises();
      expect(mockAlertDismiss).toHaveBeenCalledTimes(0);

      wrapper.setProps({ groupId });
      await waitForPromises();
      expect(mockAlertDismiss).toHaveBeenCalledTimes(1);
    });
  });

  describe('create role form', () => {
    beforeEach(async () => {
      // Show form
      createComponent({ groupId });
      findAddRoleButton().vm.$emit('click');
      await waitForPromises();
    });

    it('toggles display', async () => {
      expect(findCreateMemberRole().exists()).toBe(true);

      findCreateMemberRole().vm.$emit('cancel');
      await nextTick();

      expect(findCreateMemberRole().exists()).toBe(false);
    });

    describe('when successfully creates a new role', () => {
      it('shows toast', () => {
        findCreateMemberRole().vm.$emit('success');

        expect(mockToastShow).toHaveBeenCalledWith(I18N_CREATION_SUCCESS);
      });

      it('fetches roles', async () => {
        expect(getMemberRoles).toHaveBeenCalledTimes(1);

        findCreateMemberRole().vm.$emit('success');
        await waitForPromises();

        expect(getMemberRoles).toHaveBeenCalledTimes(2);
      });
    });
  });

  describe('table of roles', () => {
    it('shows name and id', async () => {
      createComponent({ groupId }, mountExtended);
      await waitForPromises();

      expect(findCellByText(mockResponse[0].name).exists()).toBe(true);
      expect(findCellByText(`${mockResponse[0].id}`).exists()).toBe(true);
    });

    const expectSortableColumn = async (fieldKey) => {
      createComponent({ groupId }, mountExtended);
      await waitForPromises();

      const { fields } = findTable().vm.$attrs;

      expect(fields.find((field) => field.key === fieldKey)?.sortable).toBe(true);
    };

    it('sorts columns by name', () => {
      expectSortableColumn('name');
    });

    it('sorts columns by ID', () => {
      expectSortableColumn('id');
    });

    it('sorts columns by base role', () => {
      expectSortableColumn('base_access_level');
    });

    it('shows list of standard permissions', async () => {
      createComponent({ groupId }, mountExtended);
      await waitForPromises();

      const badgesText = findCells().at(3).text();
      expect(badgesText).toContain('Read code');
      expect(badgesText).toContain('Read vulnerability');
      expect(badgesText).toContain('Admin vulnerability');
    });

    it('shows list of non-standard permissions', async () => {
      createComponent({ groupId }, mountExtended);
      await waitForPromises();

      const badgesText = findCells().at(8).text();
      expect(badgesText).toBe('non_standard_permission');
    });
  });

  describe('delete role', () => {
    const clickRoleDelete = () => {
      findButtonByText('Delete role').trigger('click');
      return nextTick();
    };

    beforeEach(async () => {
      createComponent({ groupId }, mountExtended);
      await waitForPromises();
    });

    it('shows confirm modal', async () => {
      expect(findModal().props('visible')).toBe(false);

      await clickRoleDelete();
      expect(findModal().props('visible')).toBe(true);
    });

    describe('when successful deletion', () => {
      beforeEach(async () => {
        deleteMemberRole.mockResolvedValue();
        await clickRoleDelete();
      });

      it('delete the role', async () => {
        findModal().vm.$emit('primary');
        await waitForPromises();

        expect(deleteMemberRole).toHaveBeenNthCalledWith(1, '49', '1');
      });

      it('shows toast', async () => {
        findModal().vm.$emit('primary');
        await waitForPromises();

        expect(mockToastShow).toHaveBeenCalledWith(I18N_DELETION_SUCCESS);
      });

      it('fetches roles', async () => {
        expect(getMemberRoles).toHaveBeenCalledTimes(1);

        findModal().vm.$emit('primary');
        await waitForPromises();

        expect(getMemberRoles).toHaveBeenCalledTimes(2);
      });
    });

    describe('when unsuccessful deletion of a role', () => {
      beforeEach(async () => {
        deleteMemberRole.mockRejectedValue(new Error());
        await clickRoleDelete();
      });

      it('shows alert', async () => {
        findModal().vm.$emit('primary');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: I18N_DELETION_ERROR,
          variant: VARIANT_DANGER,
        });
      });
    });
  });
});
