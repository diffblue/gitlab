import { GlBadge, GlButton, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DependenciesTable from 'ee/dependencies/components/dependencies_table.vue';
import DependencyLicenseLinks from 'ee/dependencies/components/dependency_license_links.vue';
import DependencyVulnerabilities from 'ee/dependencies/components/dependency_vulnerabilities.vue';
import stubChildren from 'helpers/stub_children';
import { makeDependency } from './utils';

describe('DependenciesTable component', () => {
  let wrapper;

  const createComponent = ({ propsData, ...options } = {}) => {
    wrapper = mount(DependenciesTable, {
      ...options,
      propsData: { ...propsData },
      stubs: { ...stubChildren(DependenciesTable), GlTable: false, DependencyLocation: false },
    });
  };

  const findTableRows = () => wrapper.findAll('tbody > tr');
  const findRowToggleButtons = () => wrapper.findAllComponents(GlButton);
  const findDependencyVulnerabilities = () => wrapper.findComponent(DependencyVulnerabilities);
  const normalizeWhitespace = (string) => string.replace(/\s+/g, ' ');

  const expectDependencyRow = (rowWrapper, dependency) => {
    const [
      componentCell,
      packagerCell,
      locationCell,
      licenseCell,
      isVulnerableCell,
    ] = rowWrapper.findAll('td').wrappers;

    expect(normalizeWhitespace(componentCell.text())).toBe(
      `${dependency.name} ${dependency.version}`,
    );

    expect(packagerCell.text()).toBe(dependency.packager);

    const locationLink = locationCell.findComponent(GlLink);
    expect(locationLink.attributes().href).toBe(dependency.location.blob_path);
    expect(locationLink.text()).toContain(dependency.location.path);

    const licenseLinks = licenseCell.findComponent(DependencyLicenseLinks);
    expect(licenseLinks.exists()).toBe(true);
    expect(licenseLinks.props()).toEqual({
      licenses: dependency.licenses,
      title: dependency.name,
    });

    const isVulnerableCellText = normalizeWhitespace(isVulnerableCell.text());
    if (dependency?.vulnerabilities?.length) {
      expect(isVulnerableCellText).toContain(`${dependency.vulnerabilities.length} vuln`);
    } else {
      expect(isVulnerableCellText).toBe('');
    }
  };

  describe('given the table is loading', () => {
    let dependencies;

    beforeEach(() => {
      dependencies = [makeDependency()];
      createComponent({
        propsData: {
          dependencies,
          isLoading: true,
        },
      });
    });

    it('renders the loading skeleton', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });

    it('does not render any dependencies', () => {
      expect(wrapper.text()).not.toContain(dependencies[0].name);
    });
  });

  describe('given an empty list of dependencies', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          dependencies: [],
          isLoading: false,
        },
      });
    });

    it('renders the table header', () => {
      const expectedLabels = DependenciesTable.fields.map(({ label }) => label);
      const headerCells = wrapper.findAll('thead th');

      expectedLabels.forEach((expectedLabel, i) => {
        expect(headerCells.at(i).text()).toContain(expectedLabel);
      });
    });

    it('does not render any rows', () => {
      expect(findTableRows()).toHaveLength(0);
    });
  });

  describe.each`
    description                                                             | vulnerabilitiesPayload
    ${'given dependencies with no vulnerabilities'}                         | ${{ vulnerabilities: [] }}
    ${'given dependencies when user is not allowed to see vulnerabilities'} | ${{}}
  `('$description', ({ vulnerabilitiesPayload }) => {
    let dependencies;

    beforeEach(() => {
      dependencies = [
        makeDependency({ ...vulnerabilitiesPayload }),
        makeDependency({ name: 'foo', ...vulnerabilitiesPayload }),
      ];

      createComponent({
        propsData: {
          dependencies,
          isLoading: false,
        },
      });
    });

    it('renders a row for each dependency', () => {
      const rows = findTableRows();

      dependencies.forEach((dependency, i) => {
        expectDependencyRow(rows.at(i), dependency);
      });
    });

    it('does not render any row toggle buttons', () => {
      expect(findRowToggleButtons()).toHaveLength(0);
    });

    it('does not render vulnerability details', () => {
      expect(findDependencyVulnerabilities().exists()).toBe(false);
    });
  });

  describe('given some dependencies with vulnerabilities', () => {
    let dependencies;

    beforeEach(() => {
      dependencies = [
        makeDependency({ name: 'qux', vulnerabilities: ['bar', 'baz'] }),
        makeDependency({ vulnerabilities: [] }),
        // Guarantee that the component doesn't mutate these, but still
        // maintains its row-toggling behaviour (i.e., via _showDetails)
      ].map(Object.freeze);

      createComponent({
        propsData: {
          dependencies,
          isLoading: false,
        },
      });
    });

    it('renders a row for each dependency', () => {
      const rows = findTableRows();

      dependencies.forEach((dependency, i) => {
        expectDependencyRow(rows.at(i), dependency);
      });
    });

    it('render the toggle button for each row', () => {
      const toggleButtons = findRowToggleButtons();

      dependencies.forEach((dependency, i) => {
        const button = toggleButtons.at(i);

        expect(button.exists()).toBe(true);
        expect(button.classes('invisible')).toBe(dependency.vulnerabilities.length === 0);
      });
    });

    it('does not render vulnerability details', () => {
      expect(findDependencyVulnerabilities().exists()).toBe(false);
    });

    describe('the dependency vulnerabilities', () => {
      let rowIndexWithVulnerabilities;

      beforeEach(() => {
        rowIndexWithVulnerabilities = dependencies.findIndex(
          (dep) => dep.vulnerabilities.length > 0,
        );
      });

      it('can be displayed by clicking on the toggle button', () => {
        const toggleButton = findRowToggleButtons().at(rowIndexWithVulnerabilities);
        toggleButton.vm.$emit('click');

        return nextTick().then(() => {
          expect(findDependencyVulnerabilities().props()).toEqual({
            vulnerabilities: dependencies[rowIndexWithVulnerabilities].vulnerabilities,
          });
        });
      });

      it('can be displayed by clicking on the vulnerabilities badge', () => {
        const badge = findTableRows().at(rowIndexWithVulnerabilities).findComponent(GlBadge);
        badge.trigger('click');

        return nextTick().then(() => {
          expect(findDependencyVulnerabilities().props()).toEqual({
            vulnerabilities: dependencies[rowIndexWithVulnerabilities].vulnerabilities,
          });
        });
      });
    });
  });
});
