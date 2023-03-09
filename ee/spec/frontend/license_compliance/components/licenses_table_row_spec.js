import { GlLink, GlSkeletonLoader, GlBadge, GlFriendlyWrap } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import LicenseComponentLinks from 'ee/license_compliance/components/license_component_links.vue';
import LicensesTableRow from 'ee/license_compliance/components/licenses_table_row.vue';
import { LICENSE_APPROVAL_CLASSIFICATION } from 'ee/vue_shared/license_compliance/constants';
import { makeLicense } from './utils';

describe('LicensesTableRow component', () => {
  let wrapper;
  let license;

  const factory = (propsData = {}) => {
    wrapper = shallowMount(LicensesTableRow, {
      propsData,
    });
  };

  const findLoading = () => wrapper.findComponent(GlSkeletonLoader);
  const findContent = () => wrapper.find('.js-license-row');
  const findNameSection = () => findContent().find('.section-30');
  const findComponentSection = () => findContent().find('.section-70');

  beforeEach(() => {
    license = makeLicense();
  });

  describe.each`
    desc                      | props
    ${'when passed no props'} | ${{}}
    ${'when loading'}         | ${{ isLoading: true }}
  `('$desc', ({ props }) => {
    beforeEach(() => {
      factory(props);
    });

    it('shows the skeleton loading component', () => {
      const loading = findLoading();
      expect(loading.exists()).toBe(true);
      expect(loading.attributes('lines')).toEqual('1');
    });

    it('does not show the content', () => {
      const content = findContent();

      expect(content.exists()).toBe(false);
    });
  });

  describe('when a license has url and components', () => {
    beforeEach(() => {
      factory({
        isLoading: false,
        license,
      });
    });

    it('shows name', () => {
      const nameLink = findNameSection().findComponent(GlLink);

      expect(nameLink.exists()).toBe(true);
      expect(nameLink.attributes('href')).toEqual(license.url);
      expect(nameLink.text()).toEqual(license.name);
    });

    it('shows components', () => {
      const componentLinks = findComponentSection().findComponent(LicenseComponentLinks);

      expect(componentLinks.exists()).toBe(true);
      expect(componentLinks.props()).toEqual(
        expect.objectContaining({
          components: license.components,
          title: license.name,
        }),
      );
    });
  });

  describe('when a license has a url in name field', () => {
    beforeEach(() => {
      license.url = null;
      license.name = 'https://github.com/dotnet/corefx/blob/master/LICENSE.TXT';

      factory({
        isLoading: false,
        license,
      });
    });

    it('renders the GlFriendlyWrap and GlLink components', () => {
      const nameSection = findNameSection();

      expect(nameSection.findComponent(GlLink).exists()).toBe(true);
      expect(nameSection.findComponent(GlFriendlyWrap).exists()).toBe(true);
      expect(nameSection.findComponent(GlFriendlyWrap).attributes().text).toBe(license.name);
    });
  });

  describe('with a license without a url', () => {
    beforeEach(() => {
      license.url = null;

      factory({
        isLoading: false,
        license,
      });
    });

    it('does not show url link for name', () => {
      const nameSection = findNameSection();

      expect(nameSection.text()).toContain(license.name);
      expect(nameSection.findComponent(GlLink).exists()).toBe(false);
    });
  });

  describe('when a license has a denied policy violation', () => {
    beforeEach(() => {
      license = makeLicense({ classification: LICENSE_APPROVAL_CLASSIFICATION.DENIED });

      factory({
        isLoading: false,
        license,
      });
    });

    it('shows the policy violation badge', () => {
      expect(wrapper.findComponent(GlBadge).exists()).toBe(true);
      expect(wrapper.findComponent(GlBadge).text()).toContain('Policy violation: denied');
    });
  });

  describe('when a license is allowed', () => {
    beforeEach(() => {
      license = makeLicense({ classification: LICENSE_APPROVAL_CLASSIFICATION.ALLOWED });

      factory({
        isLoading: false,
        license,
      });
    });

    it('does not show the policy violation badge', () => {
      expect(wrapper.findComponent(GlBadge).exists()).toBe(false);
    });
  });
});
