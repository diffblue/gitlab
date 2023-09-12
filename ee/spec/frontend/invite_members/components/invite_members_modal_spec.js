import { GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import InviteMembersModal from '~/invite_members/components/invite_members_modal.vue';
import InviteModalBase from '~/invite_members/components/invite_modal_base.vue';
import MembersTokenSelect from '~/invite_members/components/members_token_select.vue';
import { LEARN_GITLAB } from 'ee/invite_members/constants';
import eventHub from '~/invite_members/event_hub';
import ContentTransition from '~/vue_shared/components/content_transition.vue';

import {
  propsData,
  postData,
  newProjectPath,
  user1,
  user2,
} from 'jest/invite_members/mock_data/member_modal';

import {
  INVITE_MEMBERS_FOR_TASK,
  INVITE_MEMBER_MODAL_TRACKING_CATEGORY,
} from '~/invite_members/constants';

describe('EEInviteMembersModal', () => {
  let wrapper;
  let mock;
  let trackingSpy;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(InviteMembersModal, {
      provide: {
        newProjectPath,
        name: propsData.name,
      },
      propsData: {
        usersLimitDataset: {},
        activeTrialDataset: {},
        fullPath: 'project',
        ...propsData,
        ...props,
      },
      stubs: {
        InviteModalBase,
        ContentTransition,
        GlModal,
        GlSprintf,
      },
    });
  };

  const findActionButton = () => wrapper.findByTestId('invite-modal-submit');
  const emitClickFromModal = (findButton) => () =>
    findButton().vm.$emit('click', { preventDefault: jest.fn() });

  const clickInviteButton = emitClickFromModal(findActionButton);

  const findBase = () => wrapper.findComponent(InviteModalBase);
  const findMembersSelect = () => wrapper.findComponent(MembersTokenSelect);
  const findTasksToBeDone = () => wrapper.findByTestId('invite-members-modal-tasks-to-be-done');
  const findTasks = () => wrapper.findByTestId('invite-members-modal-tasks');
  const findProjectSelect = () => wrapper.findByTestId('invite-members-modal-project-select');
  const findNoProjectsAlert = () => wrapper.findByTestId('invite-members-modal-no-projects-alert');

  const expectTracking = (action, label, property) =>
    expect(trackingSpy).toHaveBeenCalledWith(INVITE_MEMBER_MODAL_TRACKING_CATEGORY, action, {
      label,
      category: INVITE_MEMBER_MODAL_TRACKING_CATEGORY,
      property,
    });

  const triggerAccessLevel = async (val) => {
    findBase().vm.$emit('access-level', val);

    await nextTick();
  };

  const triggerTasks = async (val) => {
    findTasks().vm.$emit('input', val);

    await nextTick();
  };

  const triggerOpenModal = async ({ mode = 'default', source } = {}) => {
    eventHub.$emit('openModal', { mode, source });

    await triggerAccessLevel(30);
  };

  const triggerOpenModalWithTasks = async (...args) => {
    await triggerOpenModal(...args);
    await triggerTasks(['ci', 'code']);
  };

  const triggerMembersTokenSelect = async (val) => {
    findMembersSelect().vm.$emit('input', val);

    await nextTick();
  };

  describe('when on the Learn GitLab page', () => {
    describe('rendering the tasks to be done', () => {
      beforeEach(() => {
        gon.api_version = 'v4';
        mock = new MockAdapter(axios);
      });

      afterEach(() => {
        mock.restore();
      });

      it('does render the tasks to be done', async () => {
        createComponent();

        await triggerOpenModal({ source: LEARN_GITLAB });

        expect(findTasksToBeDone().exists()).toBe(true);
      });

      describe('when the selected access level is lower than 30', () => {
        it('does not render the tasks to be done', async () => {
          createComponent();

          await triggerOpenModal({ source: LEARN_GITLAB });
          await triggerAccessLevel(20);

          expect(findTasksToBeDone().exists()).toBe(false);
        });
      });

      describe('when the source is unknown', () => {
        it('does not render the tasks to be done', async () => {
          createComponent();

          await triggerOpenModal({ source: 'unknown' });

          expect(findTasksToBeDone().exists()).toBe(false);
        });
      });

      describe('rendering the tasks', () => {
        it('renders the tasks', async () => {
          createComponent();

          await triggerOpenModal({ source: LEARN_GITLAB });

          expect(findTasks().exists()).toBe(true);
        });

        it('does not render an alert', async () => {
          createComponent();

          await triggerOpenModal({ source: LEARN_GITLAB });

          expect(findNoProjectsAlert().exists()).toBe(false);
        });

        describe('when there are no projects passed in the data', () => {
          it('does not render the tasks', async () => {
            createComponent({ projects: [] });

            await triggerOpenModal({ source: LEARN_GITLAB });

            expect(findTasks().exists()).toBe(false);
          });

          it('renders an alert with a link to the new projects path', async () => {
            createComponent({ projects: [] });

            await triggerOpenModal({ source: LEARN_GITLAB });

            expect(findNoProjectsAlert().exists()).toBe(true);

            expect(findNoProjectsAlert().findComponent(GlLink).attributes('href')).toBe(
              newProjectPath,
            );
          });
        });
      });

      describe('rendering the project dropdown', () => {
        it('renders the project select', async () => {
          createComponent();

          await triggerOpenModalWithTasks({ source: LEARN_GITLAB });

          expect(findProjectSelect().exists()).toBe(true);
        });

        describe('when the modal is shown for a project', () => {
          it('does not render the project select', async () => {
            createComponent({ isProject: true });

            await triggerOpenModalWithTasks({ source: LEARN_GITLAB });

            expect(findProjectSelect().exists()).toBe(false);
          });
        });

        describe('when no tasks are selected', () => {
          it('does not render the project select', async () => {
            createComponent();

            await triggerOpenModal({ source: LEARN_GITLAB });

            expect(findProjectSelect().exists()).toBe(false);
          });
        });
      });

      describe('tracking events', () => {
        afterEach(() => {
          unmockTracking();
        });

        it('tracks the submit for invite_members_for_task', async () => {
          createComponent();

          await triggerOpenModalWithTasks({ source: LEARN_GITLAB });
          await triggerMembersTokenSelect([user1]);

          trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

          clickInviteButton();

          expectTracking(INVITE_MEMBERS_FOR_TASK.submit, 'selected_tasks_to_be_done', 'ci,code');
        });
      });
    });

    describe('when member is added successfully', () => {
      beforeEach(async () => {
        createComponent();

        await triggerMembersTokenSelect([user1, user2]);

        jest.spyOn(Api, 'inviteGroupMembers').mockResolvedValue({ data: postData });

        clickInviteButton();
      });

      it('emits the `showSuccessfulInvitationsAlert` event', async () => {
        await triggerOpenModal({ source: LEARN_GITLAB });

        jest.spyOn(eventHub, '$emit').mockImplementation();

        clickInviteButton();

        await waitForPromises();

        expect(eventHub.$emit).toHaveBeenCalledWith('showSuccessfulInvitationsAlert');
      });
    });
  });
});
