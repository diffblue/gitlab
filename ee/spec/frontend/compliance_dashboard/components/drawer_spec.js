import { GlDrawer } from '@gitlab/ui';
import MergeRequestDrawer from 'ee/compliance_dashboard/components/drawer.vue';
import BranchPath from 'ee/compliance_dashboard/components/drawer_sections/branch_path.vue';
import Committers from 'ee/compliance_dashboard/components/drawer_sections/committers.vue';
import MergedBy from 'ee/compliance_dashboard/components/drawer_sections/merged_by.vue';
import Project from 'ee/compliance_dashboard/components/drawer_sections/project.vue';
import Reference from 'ee/compliance_dashboard/components/drawer_sections/reference.vue';
import Reviewers from 'ee/compliance_dashboard/components/drawer_sections/reviewers.vue';
import { getContentWrapperHeight } from 'ee/threat_monitoring/utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import resolvers from 'ee/compliance_dashboard/graphql/resolvers';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { mapViolations } from 'ee/compliance_dashboard/graphql/mappers';

jest.mock('ee/threat_monitoring/utils', () => ({
  getContentWrapperHeight: jest.fn(),
}));

describe('MergeRequestDrawer component', () => {
  let wrapper;
  const defaultData = mapViolations(resolvers.Query.group().mergeRequestViolations.nodes)[0];
  const data = {
    id: defaultData.id,
    mergeRequest: {
      ...defaultData.mergeRequest,
      sourceBranch: null,
      sourceBranchUri: null,
      targetBranch: null,
      targetBranchUri: null,
    },
    project: defaultData.mergeRequest.project,
  };

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
        mergeRequest: data.mergeRequest,
        project: data.project,
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
        zIndex: DRAWER_Z_INDEX,
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
      expect(findTitle().text()).toEqual(data.mergeRequest.title);
    });

    it('has the project section', () => {
      expect(findProject().props()).toStrictEqual({
        avatarUrl: data.project.avatarUrl,
        complianceFramework: data.project.complianceFramework,
        name: data.project.name,
        url: data.project.webUrl,
      });
    });

    it('has the reference section', () => {
      expect(findReference().props()).toStrictEqual({
        path: data.mergeRequest.webUrl,
        reference: data.mergeRequest.reference,
      });
    });

    it('does not have the branch section', () => {
      expect(findBranchPath().exists()).toBe(false);
    });

    it('has the committers section with users array converted to camel case', () => {
      expect(findCommitters().props()).toStrictEqual({
        committers: data.mergeRequest.committers,
      });
    });

    it('has the reviewers section with users array converted to camel case', () => {
      expect(findReviewers().props()).toStrictEqual({
        approvers: data.mergeRequest.approvedByUsers,
        commenters: data.mergeRequest.participants,
      });
    });

    it('has the merged by section', () => {
      expect(findMergedBy().props()).toStrictEqual({
        mergedBy: data.mergeRequest.mergedBy,
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
          ...data.mergeRequest,
          sourceBranch,
          sourceBranchUri,
          targetBranch,
          targetBranchUri,
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
