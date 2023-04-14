import { GlCard, GlLink } from '@gitlab/ui';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card_vuex.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';

describe('Solution Card', () => {
  const solution = 'Upgrade to XYZ';
  const remediation = { summary: 'Update to 123', fixes: [], diff: 'SGVsbG8gR2l0TGFi' };

  let wrapper;

  const createShallowComponent = (props = {}) => {
    wrapper = shallowMountExtended(SolutionCard, {
      propsData: {
        ...props,
      },
    });
  };

  const findCard = () => wrapper.findComponent(GlCard);
  const findCardFooter = () => wrapper.find('.card-footer');
  const findLink = () => wrapper.findComponent(GlLink);
  const findMergeRequestSolution = () => wrapper.findByTestId('merge-request-solution');

  describe('computed properties', () => {
    describe('solutionText', () => {
      it('takes the value of solution', () => {
        createShallowComponent({ solution });
        expect(findCard().text()).toBe(`Solution: ${solution}`);
      });

      it('takes the summary from a remediation', () => {
        createShallowComponent({ remediation });
        expect(findCard().text()).toBe(`Solution: ${remediation.summary}`);
      });

      it('takes the value of solution, if both are defined', () => {
        createShallowComponent({ remediation, solution });
        expect(findCard().text()).toBe(`Solution: ${solution}`);
      });
    });
  });

  describe('rendering', () => {
    describe('with solution', () => {
      beforeEach(() => {
        createShallowComponent({ solution });
      });

      it('does not render the card footer', () => {
        expect(findCardFooter().exists()).toBe(false);
      });

      it('does not render the download link', () => {
        expect(findLink().exists()).toBe(false);
      });
    });

    describe('with remediation', () => {
      beforeEach(() => {
        createShallowComponent({ remediation });
      });

      describe('with download patch', () => {
        it('renders the create a merge request to implement this solution message', () => {
          createShallowComponent({ remediation, hasDownload: true });
          expect(findMergeRequestSolution().text()).toBe(
            s__(
              'ciReport|Create a merge request to implement this solution, or download and apply the patch manually.',
            ),
          );
        });

        it('does not render the download and apply solution message when there is a file download and a merge request already exists', () => {
          createShallowComponent({ remediation, hasDownload: true, hasMr: true });
          expect(findCardFooter().exists()).toBe(false);
        });
      });

      describe('without download patch', () => {
        it('does not render the card footer', () => {
          expect(findMergeRequestSolution().exists()).toBe(false);
        });
      });
    });

    describe('without solution and remediation', () => {
      beforeEach(() => {
        createShallowComponent({ remediation: {}, solution: '' });
      });

      it('does not render the card', () => {
        expect(findCard().exists()).toBe(false);
      });
    });
  });
});
