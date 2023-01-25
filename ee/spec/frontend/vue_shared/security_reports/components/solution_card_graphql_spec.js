import { GlCard, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card_graphql.vue';

const TEST_SOLUTION = 'Upgrade to XYZ';
const TEST_REMEDIATION = { summary: 'Update to 123', diff: 'SGVsbG8gR2l0TGFi' };

describe('Solution Card GraphQL', () => {
  let wrapper;

  const createWrapper = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(SolutionCard, { propsData });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findGlCard = () => wrapper.findComponent(GlCard);
  const findSolutionTitle = () => wrapper.findByTestId('solution-title');
  const findSolutionText = () => wrapper.findByTestId('solution-text');

  afterEach(() => {
    wrapper.destroy();
  });

  it('does not render component when there is no solution', () => {
    createWrapper();
    expect(findGlCard().exists()).toBe(false);
  });

  it('renders the solution title', () => {
    createWrapper({ propsData: { solution: TEST_SOLUTION } });
    expect(findIcon().props('name')).toBe('bulb');
    expect(findSolutionTitle().text()).toBe('Solution:');
  });

  describe('solution text', () => {
    it('renders text from solution', () => {
      createWrapper({ propsData: { solution: TEST_SOLUTION } });
      expect(findSolutionText().text()).toBe(TEST_SOLUTION);
    });

    it('renders from remediation summary', () => {
      createWrapper({ propsData: { remediation: TEST_REMEDIATION } });
      expect(findSolutionText().text()).toBe(TEST_REMEDIATION.summary);
    });

    it('renders from solution when both solution and remediation are provided', () => {
      createWrapper({ propsData: { solution: TEST_SOLUTION, remediation: TEST_REMEDIATION } });
      expect(findSolutionText().text()).toBe(TEST_SOLUTION);
    });
  });
});
