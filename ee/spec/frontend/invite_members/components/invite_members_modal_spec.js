import { GlModal, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
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

describe('EEInviteMembersModal', () => {
  let wrapper;

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
  const triggerAccessLevel = async (val) => {
    findBase().vm.$emit('access-level', val);

    await nextTick();
  };

  const triggerOpenModal = async ({ mode = 'default', source } = {}) => {
    eventHub.$emit('openModal', { mode, source });

    await triggerAccessLevel(30);
  };

  const triggerMembersTokenSelect = async (val) => {
    findMembersSelect().vm.$emit('input', val);

    await nextTick();
  };

  describe('when on the Learn GitLab page', () => {
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
