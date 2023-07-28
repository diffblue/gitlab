import { GlBadge, GlButton, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DependenciesTable from 'ee/dependencies/components/dependencies_table.vue';
import DependencyLicenseLinks from 'ee/dependencies/components/dependency_license_links.vue';
import DependencyVulnerabilities from 'ee/dependencies/components/dependency_vulnerabilities.vue';
import DependencyLocationCount from 'ee/dependencies/components/dependency_location_count.vue';
import DependencyProjectCount from 'ee/dependencies/components/dependency_project_count.vue';
import DependencyLocation from 'ee/dependencies/components/dependency_location.vue';
import { DEPENDENCIES_TABLE_I18N } from 'ee/dependencies/constants';
import stubChildren from 'helpers/stub_children';
import { makeDependency } from './utils';

describe('DependenciesTable component', () => {
  let wrapper;

  const basicAppProps = {
    namespaceType: 'project',
    endpoint: 'endpoint',
  };

  const createComponent = ({ propsData, provide } = {}) => {
    wrapper = mount(DependenciesTable, {
      propsData: { ...propsData },
      stubs: {
        ...stubChildren(DependenciesTable),
        GlTable: false,
        DependencyLocation: false,
        DependencyProjectCount: false,
        DependencyLocationCount: false,
      },
      provide: { ...basicAppProps, ...provide },
    });
  };

  const findTableRows = () => wrapper.findAll('tbody > tr');
  const findRowToggleButtons = () => wrapper.findAllComponents(GlButton);
  const findDependencyVulnerabilities = () => wrapper.findComponent(DependencyVulnerabilities);
  const findDependencyLocation = () => wrapper.findComponent(DependencyLocation);
  const findDependencyLocationCount = () => wrapper.findComponent(DependencyLocationCount);
  const findDependencyProjectCount = () => wrapper.findComponent(DependencyProjectCount);
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

    expect(findDependencyLocation().exists()).toBe(true);
    const locationLink = locationCell.findComponent(GlLink);
    expect(locationLink.attributes().href).toBe(dependency.location.blobPath);
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

    expect(findDependencyLocationCount().exists()).toBe(false);
    expect(findDependencyProjectCount().exists()).toBe(false);
  };

  const expectGroupDependencyRow = (rowWrapper, dependency) => {
    const [componentCell, packagerCell, locationCell, projectCell] = rowWrapper.findAll(
      'td',
    ).wrappers;

    expect(normalizeWhitespace(componentCell.text())).toBe(
      `${dependency.name} ${dependency.version}`,
    );

    expect(packagerCell.text()).toBe(dependency.packager);

    const {
      occurrenceCount,
      projectCount,
      location: { path },
      project: { name },
    } = dependency;
    const locationCellText = occurrenceCount > 1 ? occurrenceCount.toString() : path;
    const projectCellText = projectCount > 1 ? projectCount.toString() : name;

    expect(locationCell.text()).toContain(locationCellText);
    expect(projectCell.text()).toContain(projectCellText);
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
    describe.each`
      namespaceType | fields
      ${'project'}  | ${DependenciesTable.projectFields}
      ${'group'}    | ${DependenciesTable.groupFields}
    `('with namespaceType set to $namespaceType', ({ namespaceType, fields }) => {
      beforeEach(() => {
        createComponent({
          propsData: {
            dependencies: [],
            isLoading: false,
          },
          provide: { namespaceType },
        });
      });

      it('renders the table header', () => {
        const expectedLabels = fields.map(({ label }) => label);
        const headerCells = wrapper.findAll('thead th');

        expectedLabels.forEach((expectedLabel, i) => {
          expect(headerCells.at(i).text()).toContain(expectedLabel);
        });
      });

      it('does not render any rows', () => {
        expect(findTableRows()).toHaveLength(0);
      });
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

  describe('with multiple dependencies sharing the same componentId', () => {
    let dependencies;
    beforeEach(() => {
      dependencies = [
        makeDependency({
          componentId: 1,
          occurrenceCount: 2,
          project: { full_path: 'full_path', name: 'name' },
          projectCount: 2,
        }),
        makeDependency({
          componentId: 1,
          occurrenceCount: 2,
          project: { full_path: 'full_path', name: 'name' },
          projectCount: 2,
        }),
        makeDependency({
          componentId: 2,
          occurrenceCount: 1,
          project: { full_path: 'full_path', name: 'name' },
          projectCount: 1,
        }),
      ];

      createComponent({
        propsData: {
          dependencies,
          isLoading: false,
        },
        provide: { namespaceType: 'group' },
      });
    });

    it('displays the dependencies grouped by componentId', () => {
      expect(findTableRows()).toHaveLength(2);
    });

    it('renders a row for each dependency', () => {
      const rows = findTableRows();
      // dependencies[1] not tested because it is duplicated
      expectGroupDependencyRow(rows.at(0), dependencies[0]);
      expectGroupDependencyRow(rows.at(1), dependencies[2]);
    });
  });

  describe('when packager is not set', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          dependencies: [
            makeDependency({
              componentId: 1,
              occurrenceCount: 1,
              project: { full_path: 'full_path', name: 'name' },
              projectCount: 1,
              packager: null,
            }),
          ],
          isLoading: false,
        },
      });
    });

    it('displays unknown', () => {
      const rows = findTableRows();
      const packagerCell = rows.at(0).findAll('td').at(1);

      expect(packagerCell.text()).toBe(DEPENDENCIES_TABLE_I18N.unknown);
    });
  });
});
