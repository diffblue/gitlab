import Vue from 'vue';
import VueApollo from 'vue-apollo';
import RuleView from 'ee/projects/settings/branch_rules/components/view/index.vue';
import branchRulesQuery from 'ee/projects/settings/branch_rules/queries/branch_rules_details.query.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  I18N,
  REQUIRED_ICON,
  NOT_REQUIRED_ICON,
  REQUIRED_ICON_CLASS,
  NOT_REQUIRED_ICON_CLASS,
} from '~/projects/settings/branch_rules/components/view/constants';
import Protection from '~/projects/settings/branch_rules/components/view/protection.vue';
import { sprintf } from '~/locale';
import {
  branchProtectionsMockResponse,
  approvalRulesMock,
  statusChecksRulesMock,
} from './mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.fn().mockReturnValue('main'),
  mergeUrlParams: jest.fn().mockReturnValue('/branches?state=all&search=main'),
  joinPaths: jest.fn(),
}));

Vue.use(VueApollo);

const protectionMockProps = {
  headerLinkHref: 'protected/branches',
  headerLinkTitle: I18N.manageProtectionsLinkTitle,
  roles: [{ accessLevelDescription: 'Maintainers' }],
  users: [{ avatarUrl: 'test.com/user.png', name: 'peter', webUrl: 'test.com' }],
};

describe('View branch rules in enterprise edition', () => {
  let wrapper;
  let fakeApollo;
  const projectPath = 'test/testing';
  const protectedBranchesPath = 'protected/branches';
  const approvalRulesPath = 'approval/rules';
  const statusChecksPath = 'status/checks';
  const branchProtectionsMockRequestHandler = (response = branchProtectionsMockResponse) =>
    jest.fn().mockResolvedValue(response);

  const createComponent = async (
    { showApprovers, showStatusChecks, showCodeOwners } = {},
    mockResponse,
  ) => {
    fakeApollo = createMockApollo([
      [branchRulesQuery, branchProtectionsMockRequestHandler(mockResponse)],
    ]);

    wrapper = shallowMountExtended(RuleView, {
      apolloProvider: fakeApollo,
      provide: {
        projectPath,
        protectedBranchesPath,
        approvalRulesPath,
        statusChecksPath,
        showApprovers,
        showStatusChecks,
        showCodeOwners,
      },
    });

    await waitForPromises();
  };

  beforeEach(() => createComponent());

  const findBranchProtections = () => wrapper.findAllComponents(Protection);
  const findApprovalsTitle = () => wrapper.findByText(I18N.approvalsTitle);
  const findStatusChecksTitle = () => wrapper.findByText(I18N.statusChecksTitle);
  const findCodeOwnerApprovalIcon = () => wrapper.findByTestId('code-owners-icon');
  const findCodeOwnerApprovalTitle = (title) => wrapper.findByText(title);
  const findCodeOwnerApprovalDescription = (description) => wrapper.findByText(description);

  it('renders a branch protection component for push rules', () => {
    expect(findBranchProtections().at(0).props()).toMatchObject({
      header: sprintf(I18N.allowedToPushHeader, { total: 2 }),
      ...protectionMockProps,
    });
  });

  it('renders a branch protection component for merge rules', () => {
    expect(findBranchProtections().at(1).props()).toMatchObject({
      header: sprintf(I18N.allowedToMergeHeader, { total: 2 }),
      ...protectionMockProps,
    });
  });

  describe('Code owner approvals', () => {
    it('does not render a code owner approval section by default', () => {
      expect(findCodeOwnerApprovalIcon().exists()).toBe(false);
      expect(findCodeOwnerApprovalTitle(I18N.requiresCodeOwnerApprovalTitle).exists()).toBe(false);
      expect(
        findCodeOwnerApprovalDescription(I18N.requiresCodeOwnerApprovalDescription).exists(),
      ).toBe(false);
    });

    it.each`
      codeOwnerApprovalRequired | iconName             | iconClass                  | title                                        | description
      ${true}                   | ${REQUIRED_ICON}     | ${REQUIRED_ICON_CLASS}     | ${I18N.requiresCodeOwnerApprovalTitle}       | ${I18N.requiresCodeOwnerApprovalDescription}
      ${false}                  | ${NOT_REQUIRED_ICON} | ${NOT_REQUIRED_ICON_CLASS} | ${I18N.doesNotRequireCodeOwnerApprovalTitle} | ${I18N.doesNotRequireCodeOwnerApprovalDescription}
    `(
      'code owners with the correct icon, title and description',
      async ({ codeOwnerApprovalRequired, iconName, iconClass, title, description }) => {
        const mockResponse = branchProtectionsMockResponse;
        mockResponse.data.project.branchRules.nodes[0].branchProtection.codeOwnerApprovalRequired = codeOwnerApprovalRequired;
        await createComponent({ showCodeOwners: true }, mockResponse);

        expect(findCodeOwnerApprovalIcon().props('name')).toBe(iconName);
        expect(findCodeOwnerApprovalIcon().attributes('class')).toBe(iconClass);
        expect(findCodeOwnerApprovalTitle(title).exists()).toBe(true);
        expect(findCodeOwnerApprovalTitle(description).exists()).toBe(true);
      },
    );
  });

  it('does not render approvals and status checks sections by default', () => {
    expect(findApprovalsTitle().exists()).toBe(false);
    expect(findStatusChecksTitle().exists()).toBe(false);
  });

  it('renders a branch protection component for approvals if "showApprovers" is true', async () => {
    await createComponent({ showApprovers: true });

    expect(findApprovalsTitle().exists()).toBe(true);

    expect(findBranchProtections().at(2).props()).toMatchObject({
      header: sprintf(I18N.approvalsHeader, { total: 3 }),
      headerLinkHref: approvalRulesPath,
      headerLinkTitle: I18N.manageApprovalsLinkTitle,
      approvals: approvalRulesMock,
    });
  });

  it('renders a branch protection component for status checks  if "showStatusChecks" is true', async () => {
    await createComponent({ showStatusChecks: true });

    expect(findStatusChecksTitle().exists()).toBe(true);

    expect(findBranchProtections().at(2).props()).toMatchObject({
      header: sprintf(I18N.statusChecksHeader, { total: statusChecksRulesMock.length }),
      headerLinkHref: statusChecksPath,
      headerLinkTitle: I18N.statusChecksLinkTitle,
      statusChecks: statusChecksRulesMock,
    });
  });
});
