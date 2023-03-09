import Vue from 'vue';
import Vuex from 'vuex';
import { GlDropdown, GlDropdownItem, GlIcon, GlButton, GlLoadingIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';

import IssueStatusIcon from '~/ci/reports/components/issue_status_icon.vue';

import AdminLicenseManagementRow from 'ee/vue_shared/license_compliance/components/admin_license_management_row.vue';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_compliance/constants';

import { allowedLicense } from '../mock_data';

const visibleClass = 'visible';
const invisibleClass = 'invisible';
const disabledObj = { disabled: 'disabled' };

Vue.use(Vuex);

describe('AdminLicenseManagementRow', () => {
  let wrapper;
  let store;
  let actions;

  const createComponent = (props = { license: allowedLicense }) => {
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

    wrapper = mountExtended(AdminLicenseManagementRow, {
      store,
      propsData: {
        ...props,
      },
    });
  };

  const findNthDropdown = (num) => wrapper.findAllComponents(GlDropdownItem).at(num);
  const findNthDropdownIcon = (num) => wrapper.findAllComponents(GlIcon).at(num);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findDropdownToggle = () => wrapper.findComponent(GlDropdown);
  const findRemoveButton = () => wrapper.findComponent(GlButton);

  describe('allowed license', () => {
    beforeEach(() => {
      createComponent({
        license: { ...allowedLicense, approvalStatus: LICENSE_APPROVAL_STATUS.ALLOWED },
      });
    });

    describe('computed', () => {
      it('dropdownText returns `Allowed`', () => {
        expect(findDropdownToggle().text()).toContain('Allowed');
      });

      it('allowedIconClass is visible', () => {
        expect(wrapper.findAllComponents(GlIcon).at(2).classes(visibleClass)).toBe(true);
      });

      it('deniedIconClass is invisible', () => {
        expect(wrapper.findAllComponents(GlIcon).at(3).classes(invisibleClass)).toBe(true);
      });
    });

    describe('template', () => {
      it('first dropdown element should have a visible icon', () => {
        const firstOption = findNthDropdownIcon(2);

        expect(firstOption.classes(visibleClass)).toBe(true);
      });

      it('second dropdown element should have no visible icon', () => {
        const secondOption = findNthDropdownIcon(3);

        expect(secondOption.classes(invisibleClass)).toBe(true);
      });
    });
  });

  describe('denied license', () => {
    beforeEach(() => {
      createComponent({
        license: { ...allowedLicense, approvalStatus: LICENSE_APPROVAL_STATUS.DENIED },
      });
    });

    describe('computed', () => {
      it('dropdownText returns `Denied`', () => {
        expect(findDropdownToggle().text()).toContain('Denied');
      });

      it('allowedIconClass is inVisible', () => {
        expect(wrapper.findAllComponents(GlIcon).at(2).classes(invisibleClass)).toBe(true);
      });

      it('deniedIconClass is visible', () => {
        expect(wrapper.findAllComponents(GlIcon).at(3).classes(visibleClass)).toBe(true);
      });
    });

    describe('template', () => {
      it('first dropdown element should have no visible icon', () => {
        const firstOption = findNthDropdownIcon(2);

        expect(firstOption.classes(invisibleClass)).toBe(true);
      });

      it('second dropdown element should have a visible icon', () => {
        const secondOption = findNthDropdownIcon(3);

        expect(secondOption.classes(visibleClass)).toBe(true);
      });
    });
  });

  describe('interaction', () => {
    beforeEach(() => {
      createComponent();
    });

    it('triggering setLicenseInModal by clicking the cancel button', () => {
      const linkEl = findRemoveButton();
      linkEl.trigger('click');

      expect(actions.setLicenseInModal).toHaveBeenCalled();
    });

    it('triggering allowLicense by clicking the first dropdown option', () => {
      const linkEl = findNthDropdownIcon(2);
      linkEl.trigger('click');

      expect(actions.allowLicense).toHaveBeenCalled();
    });

    it('triggering allowLicense denyLicense by clicking the second dropdown option', () => {
      const linkEl = findNthDropdownIcon(3);
      linkEl.trigger('click');

      expect(actions.denyLicense).toHaveBeenCalled();
    });
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders status icon', () => {
      const icon = wrapper.findComponent(IssueStatusIcon);

      expect(icon.exists()).toBe(true);
    });

    it('renders license name', () => {
      const name = wrapper.findByTestId('license-name');

      expect(name.text()).toBe(allowedLicense.name);
    });

    it('renders the removal button', () => {
      const button = findRemoveButton();

      expect(button.exists()).toBe(true);
      expect(wrapper.findByTestId('remove-icon').exists()).toBe(true);
    });

    it('renders the dropdown with `Allow` and `Deny` options', () => {
      const dropdown = findDropdownToggle();

      expect(dropdown.exists()).toBe(true);

      const firstOption = findNthDropdown(0);

      expect(firstOption.exists()).toBe(true);
      expect(firstOption.text()).toBe('Allow');

      const secondOption = findNthDropdown(1);

      expect(secondOption.exists()).toBe(true);
      expect(secondOption.text()).toBe('Deny');
    });

    it('does not show a loading icon and enables the remove button by default', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findRemoveButton().attributes()).toEqual(expect.not.objectContaining(disabledObj));
    });

    it('shows a loading icon and disables the remove button while loading', () => {
      createComponent({ license: allowedLicense, loading: true });

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findRemoveButton().attributes()).toEqual(expect.objectContaining(disabledObj));
    });
  });
});
