import Reviewers from 'ee/compliance_dashboard/components/violations_report/drawer_sections/reviewers.vue';
import DrawerSectionHeader from 'ee/compliance_dashboard/components/violations_report/shared/drawer_section_header.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createApprovers } from '../../../mock_data';

describe('Reviewers component', () => {
  let wrapper;

  const findSectionHeader = () => wrapper.findComponent(DrawerSectionHeader);
  const findCommenters = () => wrapper.findByTestId('commenters-avatar-list');
  const findApprovers = () => wrapper.findByTestId('approvers-avatar-list');

  const createComponent = (propsData = {}) => {
    return shallowMountExtended(Reviewers, {
      propsData,
    });
  };

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the header', () => {
      expect(findSectionHeader().text()).toBe('Peer review by');
    });
  });

  describe('with reviewers', () => {
    describe.each`
      prop            | findMethod        | number | header            | emptyHeader
      ${'commenters'} | ${findCommenters} | ${1}   | ${'1 commenter'}  | ${'No commenters'}
      ${'commenters'} | ${findCommenters} | ${3}   | ${'3 commenters'} | ${'No commenters'}
      ${'approvers'}  | ${findApprovers}  | ${1}   | ${'1 approver'}   | ${'No approvers'}
      ${'approvers'}  | ${findApprovers}  | ${2}   | ${'2 approvers'}  | ${'No approvers'}
    `('when $prop has $number users', ({ prop, findMethod, number, header, emptyHeader }) => {
      beforeEach(() => {
        wrapper = createComponent({ [prop]: createApprovers(number) });
      });

      it('renders the avatar list with the correct header', () => {
        expect(findMethod().props()).toMatchObject({
          header,
          emptyHeader,
        });
      });
    });

    describe('rendering', () => {
      const commenters = createApprovers(4);
      const approvers = createApprovers(2);

      beforeEach(() => {
        wrapper = createComponent({ commenters, approvers });
      });

      it('renders the commenters avatar list', () => {
        expect(findCommenters().props()).toMatchObject({
          avatars: commenters,
        });
      });

      it('renders the approvers avatar list', () => {
        expect(findApprovers().props()).toMatchObject({
          avatars: approvers,
        });
        expect(findApprovers().classes()).toContain('gl-mt-4');
      });
    });
  });
});
