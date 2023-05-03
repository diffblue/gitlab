import { GlButton, GlLoadingIcon, GlIcon, GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import LicenseComplianceApprovals from 'ee/approvals/components/license_compliance/index.vue';
import AddLicenseForm from 'ee/vue_shared/license_compliance/components/add_license_form.vue';
import AdminLicenseManagementRow from 'ee/vue_shared/license_compliance/components/admin_license_management_row.vue';
import DeleteConfirmationModal from 'ee/vue_shared/license_compliance/components/delete_confirmation_modal.vue';
import LicenseManagementRow from 'ee/vue_shared/license_compliance/components/license_management_row.vue';
import LicenseManagement from 'ee/vue_shared/license_compliance/license_management.vue';
import { allowedLicense, deniedLicense } from './mock_data';

Vue.use(Vuex);

let wrapper;

const managedLicenses = [allowedLicense, deniedLicense];

const PaginatedList = {
  props: ['list'],
  template: `
    <div>
      <slot name="header"></slot>
      <slot name="subheader"></slot>
      <slot :listItem="list[0]"></slot>
    </div>
  `,
};

const noop = () => {};
const findIcon = () => wrapper.findComponent(GlIcon);
const findPopover = () => wrapper.findComponent(GlPopover);

const createComponent = ({ state, getters, props, actionMocks, isAdmin, options, provide }) => {
  const fakeStore = new Vuex.Store({
    modules: {
      licenseManagement: {
        namespaced: true,
        getters: {
          isAddingNewLicense: () => false,
          hasPendingLicenses: () => false,
          isLicenseBeingUpdated: () => () => false,
          ...getters,
        },
        state: {
          managedLicenses,
          isLoadingManagedLicenses: true,
          isAdmin,
          knownLicenses: [],
          ...state,
        },
        actions: {
          fetchManagedLicenses: noop,
          setLicenseApproval: noop,
          ...actionMocks,
        },
      },
    },
  });

  wrapper = shallowMount(LicenseManagement, {
    propsData: {
      ...props,
    },
    stubs: {
      PaginatedList,
    },
    provide: {
      ...provide,
    },
    store: fakeStore,
    ...options,
  });
};

describe('License Management', () => {
  describe('common functionality', () => {
    describe.each`
      desc                | isAdmin
      ${'when admin'}     | ${true}
      ${'when developer'} | ${false}
    `('$desc', ({ isAdmin }) => {
      it('should render loading icon during initial loading', () => {
        createComponent({ state: { isLoadingManagedLicenses: true }, isAdmin });
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      });

      it('should render list of managed licenses while updating a license', () => {
        createComponent({
          state: { isLoadingManagedLicenses: true },
          getters: { hasPendingLicenses: () => true },
          isAdmin,
        });
        expect(wrapper.findComponent(PaginatedList).props('list')).toBe(managedLicenses);
      });

      describe('when not loading', () => {
        beforeEach(() => {
          createComponent({ state: { isLoadingManagedLicenses: false }, isAdmin });
        });

        it('should render list of managed licenses', () => {
          expect(wrapper.findComponent(PaginatedList).props('list')).toBe(managedLicenses);
        });
      });

      it('should mount and fetch licenses', () => {
        const fetchManagedLicensesMock = jest.fn();

        createComponent({
          state: { isLoadingManagedLicenses: false },
          actionMocks: {
            fetchManagedLicenses: fetchManagedLicensesMock,
          },
          isAdmin,
        });

        expect(fetchManagedLicensesMock).toHaveBeenCalledWith(expect.any(Object), undefined);
      });
    });
  });

  describe('permission based functionality', () => {
    describe('when admin', () => {
      it('should invoke `setLicenseApproval` action on `addLicense` event on form only', async () => {
        const setLicenseApprovalMock = jest.fn();
        createComponent({
          state: { isLoadingManagedLicenses: false },
          actionMocks: { setLicenseApproval: setLicenseApprovalMock },
          isAdmin: true,
        });
        wrapper.findComponent(GlButton).vm.$emit('click');

        await nextTick();
        wrapper.findComponent(AddLicenseForm).vm.$emit('addLicense');
        expect(setLicenseApprovalMock).toHaveBeenCalled();
      });

      describe('when not loading', () => {
        beforeEach(() => {
          createComponent({ state: { isLoadingManagedLicenses: false }, isAdmin: true });
        });

        it('should render the license-approvals section accordingly', () => {
          expect(wrapper.findComponent(LicenseComplianceApprovals).exists()).toBe(true);
        });

        it('should render the form if the form is open and disable the form button', async () => {
          wrapper.findComponent(GlButton).vm.$emit('click');

          await nextTick();
          expect(wrapper.findComponent(AddLicenseForm).exists()).toBe(true);
          expect(wrapper.findComponent(GlButton).attributes('disabled')).toBeDefined();
        });

        it('should not render the form if the form is closed and have active button', () => {
          expect(wrapper.findComponent(AddLicenseForm).exists()).toBe(false);
          expect(wrapper.findComponent(GlButton).attributes('disabled')).toBeUndefined();
        });

        it('should render delete confirmation modal', () => {
          expect(wrapper.findComponent(DeleteConfirmationModal).exists()).toBe(true);
        });

        it('renders the admin row', () => {
          expect(wrapper.findComponent(LicenseManagementRow).exists()).toBe(false);
          expect(wrapper.findComponent(AdminLicenseManagementRow).exists()).toBe(true);
        });
      });

      it('should not show the developer only tooltip', () => {
        createComponent({
          state: { isLoadingManagedLicenses: false },
          isAdmin: true,
        });

        expect(findIcon().exists()).toBe(false);
        expect(findPopover().exists()).toBe(false);
      });
    });

    describe('when developer', () => {
      it('should not invoke `setLicenseApproval` action or `addLicense` event on form', () => {
        const setLicenseApprovalMock = jest.fn();
        createComponent({
          state: { isLoadingManagedLicenses: false },
          actionMocks: { setLicenseApproval: setLicenseApprovalMock },
          isAdmin: false,
        });
        expect(wrapper.findComponent(GlButton).exists()).toBe(false);
        expect(wrapper.findComponent(AddLicenseForm).exists()).toBe(false);
        expect(setLicenseApprovalMock).not.toHaveBeenCalled();
      });

      describe('when not loading', () => {
        beforeEach(() => {
          createComponent({ state: { isLoadingManagedLicenses: false, isAdmin: false } });
        });

        it('should not render the approval section', () => {
          expect(wrapper.findComponent(LicenseComplianceApprovals).exists()).toBe(false);
        });

        it('should not render the form', () => {
          expect(wrapper.findComponent(AddLicenseForm).exists()).toBe(false);
          expect(wrapper.findComponent(GlButton).exists()).toBe(false);
        });

        it('should not render delete confirmation modal', () => {
          expect(wrapper.findComponent(DeleteConfirmationModal).exists()).toBe(false);
        });

        it('renders the read-only row', () => {
          expect(wrapper.findComponent(LicenseManagementRow).exists()).toBe(true);
          expect(wrapper.findComponent(AdminLicenseManagementRow).exists()).toBe(false);
        });
      });

      it('should show the developer only tooltip', () => {
        createComponent({
          state: { isLoadingManagedLicenses: false },
          isAdmin: false,
        });

        expect(findIcon().exists()).toBe(true);
        expect(findPopover().exists()).toBe(true);
      });
    });
  });
});
