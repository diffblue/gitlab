import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton } from '@gitlab/ui';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import aiActionMutation from 'ee/graphql_shared/mutations/ai_action.mutation.graphql';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import AiSummaryNotes from 'ee/notes/components/note_actions/ai_summarize_notes.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('AiSummarizeNotes component', () => {
  let wrapper;
  let aiActionMutationHandler;
  const resourceGlobalId = 'gid://gitlab/Issue/1';
  const LONGER_THAN_MAX_REQUEST_TIMEOUT = 1000 * 20; // 20 seconds

  const findButton = () => wrapper.findComponent(GlButton);

  const createWrapper = (props) => {
    aiActionMutationHandler = jest.fn();
    const mockApollo = createMockApollo([[aiActionMutation, aiActionMutationHandler]]);

    wrapper = mountExtended(AiSummaryNotes, {
      apolloProvider: mockApollo,
      propsData: {
        resourceGlobalId,
        ...props,
      },
    });
  };

  describe('on click', () => {
    describe('successful mutation', () => {
      let bsTooltipHide;

      beforeEach(async () => {
        createWrapper();

        bsTooltipHide = jest.fn();
        wrapper.vm.$root.$on(BV_HIDE_TOOLTIP, bsTooltipHide);
        aiActionMutationHandler.mockResolvedValue({ data: { aiAction: { errors: [] } } });

        await findButton().trigger('click');
        await nextTick();
      });

      it('closes tooltip', () => {
        expect(bsTooltipHide).toHaveBeenCalled();
      });

      it('calls the aiActionMutation', () => {
        expect(aiActionMutationHandler).toHaveBeenCalledWith({
          input: { summarizeComments: { resourceId: 'gid://gitlab/Issue/1' } },
        });
      });

      it('does not timeout once it has received a successful response', async () => {
        await waitForPromises();
        jest.advanceTimersByTime(LONGER_THAN_MAX_REQUEST_TIMEOUT);

        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('unsuccessful mutation', () => {
      beforeEach(() => {
        createWrapper();
        aiActionMutationHandler.mockResolvedValue({
          data: { aiAction: { errors: ['GraphQL Error'] } },
        });
        findButton().trigger('click');
      });

      it('shows error if no response within timeout limit', async () => {
        jest.advanceTimersByTime();
        await nextTick();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: 'Something went wrong',
          }),
        );
      });

      it('shows error on error response', async () => {
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: 'GraphQL Error',
          }),
        );
      });
    });
  });
});
