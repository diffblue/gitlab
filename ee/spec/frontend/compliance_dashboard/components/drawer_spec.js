import { GlDrawer } from '@gitlab/ui';
import MergeRequestDrawer from 'ee/compliance_dashboard/components/drawer.vue';
import BranchPath from 'ee/compliance_dashboard/components/drawer_sections/branch_path.vue';
import Committers from 'ee/compliance_dashboard/components/drawer_sections/committers.vue';
import MergedBy from 'ee/compliance_dashboard/components/drawer_sections/merged_by.vue';
import Project from 'ee/compliance_dashboard/components/drawer_sections/project.vue';
import Reference from 'ee/compliance_dashboard/components/drawer_sections/reference.vue';
import Reviewers from 'ee/compliance_dashboard/components/drawer_sections/reviewers.vue';
import { complianceFramework } from 'ee_jest/vue_shared/components/compliance_framework_label/mock_data';
import { getContentWrapperHeight } from 'ee/threat_monitoring/utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createApprovers, createMergeRequests } from '../mock_data';

jest.mock('ee/threat_monitoring/utils', () => ({
  getContentWrapperHeight: jest.fn(),
}));

describe('MergeRequestDrawer component', () => {
  let wrapper;
  const mergeRequest = createMergeRequests({
    count: 1,
    props: {
      compliance_management_framework: complianceFramework,
      committers: createApprovers(3),
      approved_by_users: createApprovers(2),
      participants: createApprovers(3),
    },
  })[0];

  const findTitle = () => wrapper.findByTestId('dashboard-drawer-title');
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findProject = () => wrapper.findComponent(Project);
  const findReference = () => wrapper.findComponent(Reference);
  const findBranchPath = () => wrapper.findComponent(BranchPath);
  const findCommitters = () => wrapper.findComponent(Committers);
  const findReviewers = () => wrapper.findComponent(Reviewers);
  const findMergedBy = () => wrapper.findComponent(MergedBy);

  const createComponent = (props) => {
    return shallowMountExtended(MergeRequestDrawer, {
      propsData: {
        mergeRequest,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default behaviour', () => {
    const mockHeaderHeight = '50px';

    beforeEach(() => {
      getContentWrapperHeight.mockReturnValue(mockHeaderHeight);
      wrapper = createComponent();
    });

    it('configures the drawer with header height and z-index', () => {
      expect(findDrawer().props()).toMatchObject({
        headerHeight: mockHeaderHeight,
        zIndex: 252,
      });
    });
  });

  describe('when closed', () => {
    beforeEach(() => {
      wrapper = createComponent({ showDrawer: false });
    });

    it('the drawer is not shown', () => {
      expect(findDrawer().props('open')).toBe(false);
    });

    it('the sections are not mounted', () => {
      expect(findProject().exists()).toBe(false);
    });
  });

  describe('when open', () => {
    beforeEach(() => {
      wrapper = createComponent({ showDrawer: true });
    });

    it('the drawer is shown', () => {
      expect(findDrawer().props('open')).toBe(true);
    });

    it('has the drawer title', () => {
      expect(findTitle().text()).toEqual(mergeRequest.title);
    });

    it('has the project section', () => {
      expect(findProject().props()).toStrictEqual({
        avatarUrl: mergeRequest.project.avatar_url,
        complianceFramework,
        name: mergeRequest.project.name,
        url: mergeRequest.project.web_url,
      });
    });

    it('has the reference section', () => {
      expect(findReference().props()).toStrictEqual({
        path: mergeRequest.path,
        reference: mergeRequest.reference,
      });
    });

    it('does not have the branch section', () => {
      expect(findBranchPath().exists()).toBe(false);
    });

    it('has the committers section', () => {
      expect(findCommitters().props()).toStrictEqual({
        committers: mergeRequest.committers,
      });
    });

    it('has the reviewers section', () => {
      expect(findReviewers().props()).toStrictEqual({
        approvers: mergeRequest.approved_by_users,
        commenters: mergeRequest.participants,
      });
    });

    it('has the merged by section', () => {
      expect(findMergedBy().props()).toStrictEqual({
        mergedBy: mergeRequest.merged_by,
      });
    });
  });

  describe('when the branch details are given', () => {
    const sourceBranch = 'feature-branch';
    const sourceBranchUri = '/project/feature-branch';
    const targetBranch = 'main';
    const targetBranchUri = '/project/main';

    beforeEach(() => {
      wrapper = createComponent({
        showDrawer: true,
        mergeRequest: {
          ...mergeRequest,
          source_branch: sourceBranch,
          source_branch_uri: sourceBranchUri,
          target_branch: targetBranch,
          target_branch_uri: targetBranchUri,
        },
      });
    });

    it('has the branch path section', () => {
      expect(findBranchPath().props()).toStrictEqual({
        sourceBranch,
        sourceBranchUri,
        targetBranch,
        targetBranchUri,
      });
    });
  });
});
