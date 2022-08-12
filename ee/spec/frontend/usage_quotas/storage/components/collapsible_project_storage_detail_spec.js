import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import CollapsibleProjectStorageDetail from 'ee/usage_quotas/storage/components/collapsible_project_storage_detail.vue';
import ProjectStorageDetail from 'ee/usage_quotas/storage/components/project_storage_detail.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { projects, projectHelpLinks as helpLinks } from '../mock_data';

let wrapper;
const project = projects[1];
const createComponent = () => {
  wrapper = shallowMount(CollapsibleProjectStorageDetail, {
    propsData: {
      project,
    },
    provide: {
      helpLinks,
    },
  });
};

const findProjectAvatar = () => wrapper.findComponent(ProjectAvatar);
const findTableRow = () => wrapper.find('[data-testid="projectTableRow"]');
const findProjectStorageDetail = () => wrapper.findComponent(ProjectStorageDetail);

describe('CollapsibleProjectStorageDetail', () => {
  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders project avatar', () => {
    expect(findProjectAvatar().props()).toMatchObject({
      projectId: project.id,
      projectName: project.name,
      projectAvatarUrl: project.avatarUrl,
    });
  });

  it('renders project name', () => {
    expect(wrapper.text()).toContain(project.nameWithNamespace);
  });

  it('renders formatted storage size', () => {
    expect(wrapper.text()).toContain(numberToHumanSize(project.statistics.storageSize));
  });

  describe('toggle row', () => {
    describe('on click', () => {
      it('toggles isOpen', async () => {
        expect(findProjectStorageDetail().exists()).toBe(false);

        findTableRow().trigger('click');

        await nextTick();
        expect(findProjectStorageDetail().exists()).toBe(true);
        findTableRow().trigger('click');

        await nextTick();
        expect(findProjectStorageDetail().exists()).toBe(false);
      });
    });
  });
});
