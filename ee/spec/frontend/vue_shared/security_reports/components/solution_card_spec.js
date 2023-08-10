import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';

jest.mock('~/behaviors/markdown/render_gfm');

describe('Solution Card', () => {
  const solutionText = 'Upgrade to XYZ';

  let wrapper;

  const findSolutionText = () => wrapper.findByTestId('solution-text');
  const findCreateMrMessage = () => wrapper.findByTestId('create-mr-message');
  const findSolutionTitle = () => wrapper.find('h3');

  const createComponent = ({ canDownloadPatch = false } = {}) => {
    wrapper = shallowMountExtended(SolutionCard, {
      propsData: { solutionText, canDownloadPatch },
    });
  };

  describe('with solution', () => {
    beforeEach(createComponent);

    it('renders the solution title', () => {
      expect(findSolutionTitle().text()).toBe('Solution');
    });

    it('renders the solution text', () => {
      expect(findSolutionText().text()).toBe(solutionText);
    });

    it('renders gfm', () => {
      expect(renderGFM).toHaveBeenCalledWith(findSolutionText().element);
    });
  });

  describe('canDownloadPatch prop', () => {
    it('shows create merge request message if patch can be downloaded', () => {
      createComponent({ canDownloadPatch: true });

      expect(findCreateMrMessage().text()).toBe(SolutionCard.i18n.createMergeRequestMsg);
    });

    it(`hides create merge request message if patch can't be downloaded`, () => {
      createComponent({ canDownloadPatch: false });

      expect(findCreateMrMessage().exists()).toBe(false);
    });
  });
});
