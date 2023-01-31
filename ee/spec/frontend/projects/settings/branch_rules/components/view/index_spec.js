import Vue from 'vue';
import VueApollo from 'vue-apollo';
import RuleView from 'ee/projects/settings/branch_rules/components/view/index.vue';
import branchRulesQuery from 'ee/projects/settings/branch_rules/queries/branch_rules_details.query.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { I18N } from '~/projects/settings/branch_rules/components/view/constants';
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
  const branchProtectionsMockRequestHandler = jest
    .fn()
    .mockResolvedValue(branchProtectionsMockResponse);

  const createComponent = async () => {
    fakeApollo = createMockApollo([[branchRulesQuery, branchProtectionsMockRequestHandler]]);

    wrapper = shallowMountExtended(RuleView, {
      apolloProvider: fakeApollo,
      provide: { projectPath, protectedBranchesPath, approvalRulesPath, statusChecksPath },
    });

    await waitForPromises();
  };

  beforeEach(() => createComponent());

  afterEach(() => wrapper.destroy());

  const findBranchProtections = () => wrapper.findAllComponents(Protection);
  const findApprovalsTitle = () => wrapper.findByText(I18N.approvalsTitle);
  const findStatusChecksTitle = () => wrapper.findByText(I18N.statusChecksTitle);

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

  it('renders a branch protection component for approvals', () => {
    expect(findApprovalsTitle().exists()).toBe(true);

    expect(findBranchProtections().at(2).props()).toMatchObject({
      header: sprintf(I18N.approvalsHeader, { total: 3 }),
      headerLinkHref: approvalRulesPath,
      headerLinkTitle: I18N.manageApprovalsLinkTitle,
      approvals: approvalRulesMock,
    });
  });

  it('renders a branch protection component for status checks', () => {
    expect(findStatusChecksTitle().exists()).toBe(true);

    expect(findBranchProtections().at(3).props()).toMatchObject({
      header: sprintf(I18N.statusChecksHeader, { total: statusChecksRulesMock.length }),
      headerLinkHref: statusChecksPath,
      headerLinkTitle: I18N.statusChecksLinkTitle,
      statusChecks: statusChecksRulesMock,
    });
  });
});
