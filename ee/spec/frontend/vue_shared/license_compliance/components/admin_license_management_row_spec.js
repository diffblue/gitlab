import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';

import AdminLicenseManagementRow from 'ee/vue_shared/license_compliance/components/admin_license_management_row.vue';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_compliance/constants';

import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import { approvedLicense } from '../mock_data';

const visibleClass = 'visible';
const invisibleClass = 'invisible';

Vue.use(Vuex);

describe('AdminLicenseManagementRow', () => {
  const Component = Vue.extend(AdminLicenseManagementRow);

  let vm;
  let store;
  let actions;

  const createComponent = (props = { license: approvedLicense }) => {
    vm = mountComponentWithStore(Component, { props, store });
  };

  const findNthDropdown = (num) => [...vm.$el.querySelectorAll('.dropdown-item')][num];
  const findNthDropdownIcon = (num) => findNthDropdown(num).querySelector('svg');
  const findLoadingIcon = () => vm.$el.querySelector('.js-loading-icon');
  const findDropdownToggle = () => vm.$el.querySelector('.dropdown > button');
  const findRemoveButton = () => vm.$el.querySelector('.js-remove-button');

  beforeEach(() => {
    actions = {
      setLicenseInModal: jest.fn(),
      allowLicense: jest.fn(),
      denyLicense: jest.fn(),
    };

    store = new Vuex.Store({
      modules: {
        licenseManagement: {
          namespaced: true,
          state: {},
          actions,
        },
      },
    });

    createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('approved license', () => {
    beforeEach(async () => {
      vm.license = { ...approvedLicense, approvalStatus: LICENSE_APPROVAL_STATUS.ALLOWED };
      await nextTick();
    });

    describe('computed', () => {
      it('dropdownText returns `Allowed`', () => {
        expect(vm.dropdownText).toBe('Allowed');
      });

      it('isApproved returns `true`', () => {
        expect(vm.approveIconClass).toBe(visibleClass);
      });

      it('isBlacklisted returns `false`', () => {
        expect(vm.blacklistIconClass).toBe(invisibleClass);
      });
    });

    describe('template', () => {
      it('first dropdown element should have a visible icon', () => {
        const firstOption = findNthDropdownIcon(0);

        expect(firstOption.classList).toContain(visibleClass);
      });

      it('second dropdown element should have no visible icon', () => {
        const secondOption = findNthDropdownIcon(1);

        expect(secondOption.classList).toContain(invisibleClass);
      });
    });
  });

  describe('blacklisted license', () => {
    beforeEach(async () => {
      vm.license = { ...approvedLicense, approvalStatus: LICENSE_APPROVAL_STATUS.DENIED };
      await nextTick();
    });

    describe('computed', () => {
      it('dropdownText returns `Denied`', () => {
        expect(vm.dropdownText).toBe('Denied');
      });

      it('isApproved returns `false`', () => {
        expect(vm.approveIconClass).toBe(invisibleClass);
      });

      it('isBlacklisted returns `true`', () => {
        expect(vm.blacklistIconClass).toBe(visibleClass);
      });
    });

    describe('template', () => {
      it('first dropdown element should have no visible icon', () => {
        const firstOption = findNthDropdownIcon(0);

        expect(firstOption.classList).toContain(invisibleClass);
      });

      it('second dropdown element should have a visible icon', () => {
        const secondOption = findNthDropdownIcon(1);

        expect(secondOption.classList).toContain(visibleClass);
      });
    });
  });

  describe('interaction', () => {
    it('triggering setLicenseInModal by clicking the cancel button', () => {
      const linkEl = findRemoveButton();
      linkEl.click();

      expect(actions.setLicenseInModal).toHaveBeenCalled();
    });

    it('triggering allowLicense by clicking the first dropdown option', () => {
      const linkEl = findNthDropdown(0);
      linkEl.click();

      expect(actions.allowLicense).toHaveBeenCalled();
    });

    it('triggering allowLicense denyLicense by clicking the second dropdown option', () => {
      const linkEl = findNthDropdown(1);
      linkEl.click();

      expect(actions.denyLicense).toHaveBeenCalled();
    });
  });

  describe('template', () => {
    it('renders component container element as a div', () => {
      expect(vm.$el.tagName).toBe('DIV');
    });

    it('renders status icon', () => {
      const iconEl = vm.$el.querySelector('.report-block-list-icon');

      expect(iconEl).not.toBeNull();
    });

    it('renders license name', () => {
      const nameEl = vm.$el.querySelector('.js-license-name');

      expect(nameEl.innerText.trim()).toBe(approvedLicense.name);
    });

    it('renders the removal button', () => {
      const buttonEl = findRemoveButton();

      expect(buttonEl).not.toBeNull();
      expect(buttonEl.querySelector('[data-testid="remove-icon"]')).not.toBeNull();
    });

    it('renders computed property dropdownText into dropdown toggle', () => {
      const dropdownEl = vm.$el.querySelector('.dropdown-toggle');

      expect(dropdownEl.innerText.trim()).toBe(vm.dropdownText);
    });

    it('renders the dropdown with `Allow` and `Deny` options', () => {
      const dropdownEl = vm.$el.querySelector('.dropdown');

      expect(dropdownEl).not.toBeNull();

      const firstOption = findNthDropdown(0);

      expect(firstOption).not.toBeNull();
      expect(firstOption.innerText.trim()).toBe('Allow');

      const secondOption = findNthDropdown(1);

      expect(secondOption).not.toBeNull();
      expect(secondOption.innerText.trim()).toBe('Deny');
    });

    it('does not show a loading icon and enables both the dropdown and the remove button by default', () => {
      expect(findLoadingIcon()).toBeNull();
      expect(findDropdownToggle().disabled).toBe(false);
      expect(findRemoveButton().disabled).toBe(false);
    });

    it('shows a loading icon and disables both the dropdown and the remove button while loading', () => {
      createComponent({ license: approvedLicense, loading: true });
      expect(findLoadingIcon()).not.toBeNull();
      expect(findDropdownToggle().disabled).toBe(true);
      expect(findRemoveButton().disabled).toBe(true);
    });
  });
});
