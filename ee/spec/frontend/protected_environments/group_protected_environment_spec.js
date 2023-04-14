import { GlAvatar, GlPopover } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import GroupProtectedEnvironment from 'ee/protected_environments/group_protected_environment.vue';

jest.mock('~/api');

describe('ee/protected_environments/group_protected_environment.vue', () => {
  const DEFAULT_ACCESS = [
    { id: 1, type: 'group', group_id: 72 },
    { id: 3, type: 'group', group_id: 73 },
  ];
  let wrapper;

  const createGroup = (id) => ({
    id,
    name: `group ${id}`,
    full_name: `group / ${id}`,
    web_url: `/group/${id}`,
    avatar_url: `/group/${id}.jpg`,
  });

  const createComponent = async ({
    project = '',
    environment = '',
    accessLevels = DEFAULT_ACCESS,
  } = {}) => {
    wrapper = mountExtended(GroupProtectedEnvironment, {
      propsData: {
        accessLevels,
        project,
        environment,
      },
    });

    await waitForPromises();
  };

  describe('success', () => {
    beforeEach(async () => {
      Api.group.mockImplementation((id) => Promise.resolve(createGroup(id)));
      await createComponent();
    });

    it('shows the number of groups with deploy acces', () => {
      const button = wrapper.findByRole('button', { name: '2 groups' });

      expect(button.exists()).toBe(true);
    });

    it('connects the button to the popover', () => {
      const button = wrapper.findByRole('button', { name: '2 groups' });
      const popover = wrapper.findComponent(GlPopover);

      expect(popover.attributes('target')).toBe(button.attributes('id'));
    });

    it('shows links to all groups', () => {
      DEFAULT_ACCESS.map((a) => createGroup(a.group_id)).forEach((group, index) => {
        const link = wrapper.findByRole('link', { name: group.full_name, hidden: true });
        expect(link.attributes('href')).toBe(group.web_url);

        const avatar = wrapper.findAllComponents(GlAvatar).wrappers[index];

        expect(avatar.props()).toMatchObject({
          src: group.avatar_url,
          entityId: group.id,
          entityName: group.name,
          shape: 'rect',
        });
      });
    });
  });

  describe('failure', () => {
    beforeEach(async () => {
      Api.group.mockRejectedValue(new Error('nope'));

      await createComponent({ accessLevels: [DEFAULT_ACCESS[0]] });
    });

    it('should show text that loading failed', () => {
      const popover = wrapper.findComponent(GlPopover);

      expect(popover.text()).toContain('Failed to load details for this group.');
    });
  });
});
