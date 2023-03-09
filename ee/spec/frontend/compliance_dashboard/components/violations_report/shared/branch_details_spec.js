import { GlLink } from '@gitlab/ui';
import BranchDetails from 'ee/compliance_dashboard/components/violations_report/shared/branch_details.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('BranchDetails component', () => {
  let wrapper;

  // The truncate component adds left-to-right marks into the text that we have to remove
  const getText = () => wrapper.text().replace(/\u200E/gi, '');
  const linkExists = (testId) => wrapper.findByTestId(testId).exists();

  const createComponent = ({ sourceUri = '', targetUri = '' } = {}) => {
    return mountExtended(BranchDetails, {
      propsData: {
        sourceBranch: {
          name: 'feature',
          uri: sourceUri,
        },
        targetBranch: {
          name: 'main',
          uri: targetUri,
        },
      },
    });
  };

  describe('with branch details', () => {
    describe('and no branch URIs', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('has no links', () => {
        expect(wrapper.findComponent(GlLink).exists()).toBe(false);
      });

      it('has the correct text', () => {
        expect(getText()).toEqual('feature into main');
      });
    });

    describe('and one branch URI', () => {
      beforeEach(() => {
        wrapper = createComponent({ targetUri: '/main-uri' });
      });

      it('has one link', () => {
        expect(wrapper.findAllComponents(GlLink)).toHaveLength(1);
      });

      it('has a link to the target branch', () => {
        expect(linkExists('target-branch-uri')).toBe(true);
      });

      it('has the correct text', () => {
        expect(getText()).toEqual('feature into main');
      });
    });

    describe('and both branch URIs', () => {
      beforeEach(() => {
        wrapper = createComponent({ sourceUri: '/feature-uri', targetUri: '/main-uri' });
      });

      it('has two links', () => {
        expect(wrapper.findAllComponents(GlLink)).toHaveLength(2);
      });

      it('has a link to the source branch', () => {
        expect(linkExists('source-branch-uri')).toBe(true);
      });

      it('has a link to the target branch', () => {
        expect(linkExists('target-branch-uri')).toBe(true);
      });

      it('has the correct text', () => {
        expect(getText()).toEqual('feature into main');
      });
    });
  });
});
