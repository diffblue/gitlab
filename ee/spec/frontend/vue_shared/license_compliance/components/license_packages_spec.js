import { mount } from '@vue/test-utils';

import LicensePackages from 'ee/vue_shared/license_compliance/components/license_packages.vue';
import { licenseReport } from '../mock_data';

const examplePackages = licenseReport[0].packages;

describe('LicensePackages', () => {
  let wrapper;

  const createComponent = (packages = examplePackages) => {
    wrapper = mount(LicensePackages, { propsData: { packages } });
  };

  const findShowAllPackagesButton = () => wrapper.find('.btn-show-all-packages');
  const findLicenseDependecies = () => wrapper.find('.js-license-dependencies');

  it('renders packages list for a particular license', () => {
    createComponent();

    const packages = findLicenseDependecies();

    expect(packages.exists()).toBe(true);
    expect(packages.text()).toBe('Used by pg, puma, foo, and');
  });

  it('renders more packages button element', () => {
    createComponent();

    const button = findShowAllPackagesButton();

    expect(button.exists()).toBe(true);
    expect(button.text()).toBe('2 more');
  });

  it('does not render more packages button when count of packages does not exceed `displayPackageCount`', () => {
    createComponent(examplePackages.slice(0, 1));

    expect(findShowAllPackagesButton().exists()).toBe(false);
  });

  it('renders all packages when show all packages button is clicked', async () => {
    createComponent();

    await findShowAllPackagesButton().trigger('click');

    expect(findLicenseDependecies().text()).toBe('Used by pg, puma, foo, bar, and baz');
  });
});
