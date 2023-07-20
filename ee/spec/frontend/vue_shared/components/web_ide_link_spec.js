import { nextTick } from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import GetProjectDetailsQuery from 'ee_component/remote_development/components/common/get_project_details_query.vue';
import WorkspacesDropdownGroup from 'ee_component/remote_development/components/workspaces_dropdown_group/workspaces_dropdown_group.vue';
import CeWebIdeLink from '~/vue_shared/components/web_ide_link.vue';
import WebIdeLink from 'ee_component/vue_shared/components/web_ide_link.vue';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

jest.mock('~/lib/utils/url_utility');

describe('ee_component/vue_shared/components/web_ide_link', () => {
  const projectId = 1;
  const newWorkspacePath = 'workspaces/new';
  const projectPath = 'bar/foo';
  let wrapper;

  function createComponent({ props = {}, provide = {} } = {}) {
    wrapper = shallowMountExtended(WebIdeLink, {
      propsData: {
        projectId,
        projectPath,
        ...props,
      },
      provide: {
        ...provide,
      },
      stubs: {
        WorkspacesDropdownGroup: stubComponent(WorkspacesDropdownGroup),
        CeWebIdeLink,
      },
    });
  }

  const findCeWebIdeLink = () => wrapper.findComponent(CeWebIdeLink);
  const findWorkspacesDropdownGroup = () => wrapper.findComponent(WorkspacesDropdownGroup);
  const findGetProjectDetailsQuery = () => wrapper.findComponent(GetProjectDetailsQuery);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  describe('default', () => {
    it('does not render workspaces dropdown group', () => {
      createComponent();

      expect(findWorkspacesDropdownGroup().exists()).toBe(false);
    });

    it('passes down properties to the CEWebIdeLink component', () => {
      createComponent({ props: { isBlob: true } });

      expect(findCeWebIdeLink().props('isBlob')).toBe(true);
    });

    it('bubbles up edit event emitted by CeWebIdeLink', () => {
      createComponent();

      findCeWebIdeLink().vm.$emit('edit', true);

      expect(wrapper.emitted('edit')).toEqual([[true]]);
    });
  });

  describe.each`
    rdAvailable | rdFFlagEnabled | executed
    ${true}     | ${true}        | ${true}
    ${true}     | ${false}       | ${false}
    ${false}    | ${true}        | ${false}
  `(
    'when rdAvailable=$rdAvailable, rdFFlagEnabled=$rdFFlagEnabled',
    ({ rdAvailable, rdFFlagEnabled, executed }) => {
      it(`getProjectDetailsQuery is${executed ? ' ' : ' not '}executed`, async () => {
        createComponent({
          provide: {
            glFeatures: {
              remoteDevelopment: rdAvailable,
              remoteDevelopmentFeatureFlag: rdFFlagEnabled,
            },
          },
        });

        findCeWebIdeLink().vm.$emit('shown');

        await nextTick();

        expect(findGetProjectDetailsQuery().exists()).toBe(executed);
      });
    },
  );

  describe('when remote development feature flags are on', () => {
    describe('when workspaces dropdown group is visible', () => {
      beforeEach(async () => {
        createComponent({
          props: { projectId, projectPath },
          provide: {
            newWorkspacePath,
            glFeatures: {
              remoteDevelopment: true,
              remoteDevelopmentFeatureFlag: true,
            },
          },
        });

        findCeWebIdeLink().vm.$emit('shown');

        await nextTick();
      });

      it('provides required parameters to GetProjectDetailsQuery', () => {
        expect(findGetProjectDetailsQuery().props()).toEqual({
          projectFullPath: projectPath,
        });
      });

      it('displays loading indicator', () => {
        expect(findLoadingIcon().exists()).toBe(true);
      });

      describe('when project hasDevFile and cluster agents', () => {
        beforeEach(async () => {
          findGetProjectDetailsQuery().vm.$emit('result', {
            hasDevFile: true,
            clusterAgents: [{}],
          });

          await nextTick();
        });

        it('hides loading icon', () => {
          expect(findLoadingIcon().exists()).toBe(false);
        });

        it('shows workspaces dropdown group above the edit actions', () => {
          expect(findWorkspacesDropdownGroup().props()).toEqual({
            projectId,
            projectFullPath: projectPath,
            newWorkspacePath,
            borderPosition: 'bottom',
            supportsWorkspaces: true,
          });
        });
      });

      describe.each([
        { hasDevFile: false, clusterAgents: [{}] },
        { hasDevFile: true, clusterAgents: [] },
      ])('when does not have devfile or cluster agents', (result) => {
        beforeEach(async () => {
          findGetProjectDetailsQuery().vm.$emit('result', result);

          await nextTick();
        });

        it('hides loading icon', () => {
          expect(findLoadingIcon().exists()).toBe(false);
        });

        it('shows workspaces dropdown group below the edit actions', () => {
          expect(findWorkspacesDropdownGroup().props()).toEqual({
            projectId,
            projectFullPath: projectPath,
            newWorkspacePath,
            borderPosition: 'top',
            supportsWorkspaces: false,
          });
        });
      });
    });
  });
});
