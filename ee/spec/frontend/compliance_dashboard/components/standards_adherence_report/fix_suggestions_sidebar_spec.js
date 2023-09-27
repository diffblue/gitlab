import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FixSuggestionsSidebar from 'ee/compliance_dashboard/components/standards_adherence_report/fix_suggestions_sidebar.vue';
import { DOCS_URL_IN_EE_DIR } from '~/lib/utils/url_utility';

describe('FixSuggestionsSidebar component', () => {
  let wrapper;

  const findRequirementSectionTitle = () => wrapper.findByTestId('sidebar-requirement-title');
  const findRequirementSectionContent = () => wrapper.findByTestId('sidebar-requirement-content');
  const findFailureSectionReasonTitle = () => wrapper.findByTestId('sidebar-failure-title');
  const findFailureSectionReasonContent = () => wrapper.findByTestId('sidebar-failure-content');
  const findSuccessSectionReasonContent = () => wrapper.findByTestId('sidebar-success-content');
  const findHowToFixSection = () => wrapper.findByTestId('sidebar-how-to-fix');
  const findManageRulesBtn = () => wrapper.findByTestId('sidebar-mr-settings-button');
  const findLearnMoreBtn = () => wrapper.findByTestId('sidebar-mr-settings-learn-more-button');

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(FixSuggestionsSidebar, {
      propsData: {
        showDrawer: true,
        groupPath: 'example-group',
        ...propsData,
      },
    });
  };

  describe('default behavior', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          adherence: {
            checkName: '',
            status: 'FAIL',
            project: {
              id: 'gid://gitlab/Project/21',
              name: 'example project',
            },
          },
        },
      });
    });

    describe('for drawer body content', () => {
      it('renders the `requirement` title', () => {
        expect(findRequirementSectionTitle().text()).toBe('Requirement');
      });

      it('renders the `failure reason` title', () => {
        expect(findFailureSectionReasonTitle().text()).toBe('Failure reason');
      });

      it('renders the `how to fix` title and description', () => {
        expect(findHowToFixSection().text()).toContain('How to fix');
        expect(findHowToFixSection().text()).toContain(
          'The following features help satisfy this requirement',
        );
      });
    });
  });

  describe('content for each check type related to MRs', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          adherence: {
            checkName: 'PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR',
            status: 'FAIL',
            project: {
              id: 'gid://gitlab/Project/21',
              name: 'example project',
              webUrl: 'example.com/groups/example-group/example-project',
            },
          },
        },
      });
    });

    describe('for failed checks', () => {
      describe('for the `how to fix` section', () => {
        it('has the details', () => {
          expect(findHowToFixSection().text()).toContain('Merge request approval rules');

          expect(findHowToFixSection().text()).toContain(
            "Update approval settings in the project's merge request settings to satisfy this requirement.",
          );
        });

        it('has the `manage rules` button', () => {
          expect(findManageRulesBtn().text()).toBe('Manage rules');

          expect(findManageRulesBtn().attributes('href')).toBe(
            'example.com/groups/example-group/example-project/-/settings/merge_requests',
          );
        });
      });

      describe.each`
        checkName                                         | expectedRequirement                                                                                  | expectedFailureReason                                                        | expectedLearnMoreDocsLink
        ${'PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR'}     | ${'Have a valid rule that prevents author-approved merge requests from being merged'}                | ${'No rule is configured to prevent author approved merge requests.'}        | ${`${DOCS_URL_IN_EE_DIR}/user/compliance/compliance_center/#prevent-authors-as-approvers`}
        ${'PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS'} | ${'Have a valid rule that prevents users from approving merge requests where they’ve added commits'} | ${'No rule is configured to prevent merge requests approved by committers.'} | ${`${DOCS_URL_IN_EE_DIR}/user/compliance/compliance_center/#prevent-committers-as-approvers`}
        ${'AT_LEAST_TWO_APPROVALS'}                       | ${'Have a valid rule that prevents merge requests with less than two approvals from being merged'}   | ${'No rule is configured to require two approvals.'}                         | ${`${DOCS_URL_IN_EE_DIR}/user/compliance/compliance_center/#at-least-two-approvals`}
      `(
        'when check is $checkName',
        ({ checkName, expectedRequirement, expectedFailureReason, expectedLearnMoreDocsLink }) => {
          beforeEach(() => {
            createComponent({
              propsData: {
                adherence: {
                  checkName,
                  status: 'FAIL',
                  project: {
                    id: 'gid://gitlab/Project/21',
                    name: 'example project',
                  },
                },
              },
            });
          });

          it('renders the requirement', () => {
            expect(findRequirementSectionContent().text()).toBe(expectedRequirement);
          });

          it('renders the failure reason', () => {
            expect(findFailureSectionReasonContent().text()).toBe(expectedFailureReason);
          });

          it('renders the `learn more` button with the correct href', () => {
            expect(findLearnMoreBtn().attributes('href')).toBe(expectedLearnMoreDocsLink);
          });
        },
      );
    });

    describe('for passed checks', () => {
      describe.each`
        checkName                                         | expectedRequirement                                                                                  | expectedSuccessReason
        ${'PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR'}     | ${'Have a valid rule that prevents author-approved merge requests from being merged'}                | ${'A rule is configured to prevent author approved merge requests.'}
        ${'PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS'} | ${'Have a valid rule that prevents users from approving merge requests where they’ve added commits'} | ${'A rule is configured to prevent merge requests approved by committers.'}
        ${'AT_LEAST_TWO_APPROVALS'}                       | ${'Have a valid rule that prevents merge requests with less than two approvals from being merged'}   | ${'A rule is configured to require two approvals.'}
      `('when check is $checkName', ({ checkName, expectedRequirement, expectedSuccessReason }) => {
        beforeEach(() => {
          createComponent({
            propsData: {
              adherence: {
                checkName,
                status: 'PASS',
                project: {
                  id: 'gid://gitlab/Project/21',
                  name: 'example project',
                },
              },
            },
          });
        });

        it('renders the requirement', () => {
          expect(findRequirementSectionContent().text()).toBe(expectedRequirement);
        });

        it('renders the success reason', () => {
          expect(findSuccessSectionReasonContent().text()).toBe(expectedSuccessReason);
        });
      });
    });
  });
});
