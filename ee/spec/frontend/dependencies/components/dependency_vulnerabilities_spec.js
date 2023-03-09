import { shallowMount } from '@vue/test-utils';
import { MAX_DISPLAYED_VULNERABILITIES_PER_DEPENDENCY } from 'ee/dependencies/components/constants';
import DependencyVulnerabilities from 'ee/dependencies/components/dependency_vulnerabilities.vue';
import DependencyVulnerability from 'ee/dependencies/components/dependency_vulnerability.vue';
import mockDataVulnerabilities from 'ee_jest/security_dashboard/store/modules/vulnerabilities/data/mock_data_vulnerabilities';

describe('DependencVulnerabilities component', () => {
  let wrapper;

  const factory = ({ vulnerabilities }) => {
    wrapper = shallowMount(DependencyVulnerabilities, {
      propsData: { vulnerabilities },
    });
  };

  const findVulnerabilities = () => wrapper.findAllComponents(DependencyVulnerability);
  const findExcessMessage = () => wrapper.findComponent({ ref: 'excessMessage' });

  describe('given no vulnerabilities', () => {
    beforeEach(() => {
      factory({ vulnerabilities: [] });
    });

    it('renders an empty list', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('given some vulnerabilities', () => {
    beforeEach(() => {
      factory({ vulnerabilities: mockDataVulnerabilities });
    });

    it('renders each vulnerability', () => {
      const components = findVulnerabilities();
      mockDataVulnerabilities.forEach((vulnerability, i) => {
        expect(components.at(i).props('vulnerability')).toBe(vulnerability);
      });
    });
  });

  describe('given a huge number vulnerabilities', () => {
    beforeEach(() => {
      const hugeNumberOfVulnerabilities = Array(1 + MAX_DISPLAYED_VULNERABILITIES_PER_DEPENDENCY)
        .fill(null)
        .map((_, id) => ({ id }));

      factory({ vulnerabilities: hugeNumberOfVulnerabilities });
    });

    it('does not render all of them', () => {
      expect(findVulnerabilities()).toHaveLength(MAX_DISPLAYED_VULNERABILITIES_PER_DEPENDENCY);
    });

    it('renders the excess message', () => {
      expect(findExcessMessage().element).toMatchSnapshot();
    });
  });
});
