import { GlModal } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoardForm from 'ee/boards/components/board_form.vue';
import createEpicBoardMutation from 'ee/boards/graphql/epic_board_create.mutation.graphql';
import destroyEpicBoardMutation from 'ee/boards/graphql/epic_board_destroy.mutation.graphql';
import updateEpicBoardMutation from 'ee/boards/graphql/epic_board_update.mutation.graphql';

import waitForPromises from 'helpers/wait_for_promises';

import { formType } from '~/boards/constants';
import updateBoardMutation from '~/boards/graphql/board_update.mutation.graphql';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
  stripFinalUrlSegment: jest.requireActual('~/lib/utils/url_utility').stripFinalUrlSegment,
  getParameterByName: jest.fn().mockName('getParameterByName'),
}));

Vue.use(Vuex);

const currentBoard = {
  id: 'gid://gitlab/Board/1',
  name: 'test',
  labels: [],
  milestone: {},
  assignee: {},
  iteration: {},
  iterationCadence: {},
  weight: null,
  hideBacklogList: false,
  hideClosedList: false,
};

const currentEpicBoard = {
  ...currentBoard,
  id: 'gid://gitlab/Boards::EpicBoard/321',
};

const defaultProps = {
  canAdminBoard: false,
  currentBoard,
  currentPage: '',
};

describe('BoardForm', () => {
  let wrapper;
  let mutate;
  let store;

  const findModal = () => wrapper.findComponent(GlModal);
  const findModalActionPrimary = () => findModal().props('actionPrimary');
  const findFormWrapper = () => wrapper.findByTestId('board-form-wrapper');
  const findDeleteConfirmation = () => wrapper.findByTestId('delete-confirmation-message');
  const findInput = () => wrapper.find('#board-new-name');

  const setBoardMock = jest.fn();
  const setErrorMock = jest.fn();

  const createStore = ({ getters = {} } = {}) => {
    store = new Vuex.Store({
      getters: {
        ...getters,
      },
      actions: {
        setBoard: setBoardMock,
        setError: setErrorMock,
      },
    });
  };

  const createComponent = ({
    props,
    iterationCadences = false,
    isIssueBoard = false,
    isEpicBoard = true,
  } = {}) => {
    wrapper = shallowMountExtended(BoardForm, {
      propsData: { ...defaultProps, ...props },
      provide: {
        boardBaseUrl: 'root',
        glFeatures: { iterationCadences },
        isIssueBoard,
        isEpicBoard,
        isGroupBoard: true,
        isProjectBoard: false,
      },
      mocks: {
        $apollo: {
          mutate,
        },
      },
      attachTo: document.body,
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mutate = null;
    store = null;
  });

  describe('when creating a new epic board', () => {
    beforeEach(() => {
      createStore();
    });

    describe('on non-scoped-board', () => {
      beforeEach(() => {
        createComponent({ props: { canAdminBoard: true, currentPage: formType.new } });
      });

      it('clears the form', () => {
        expect(findInput().element.value).toBe('');
      });

      it('shows a correct title about creating a board', () => {
        expect(findModal().attributes('title')).toBe('Create new board');
      });

      it('passes correct primary action text and variant', () => {
        expect(findModalActionPrimary().text).toBe('Create board');
        expect(findModalActionPrimary().attributes[0].variant).toBe('confirm');
      });

      it('does not render delete confirmation message', () => {
        expect(findDeleteConfirmation().exists()).toBe(false);
      });

      it('renders form wrapper', () => {
        expect(findFormWrapper().exists()).toBe(true);
      });
    });

    describe('when submitting a create event', () => {
      const fillForm = () => {
        findInput().value = 'Test name';
        findInput().trigger('input');
        findInput().trigger('keyup.enter', { metaKey: true });
      };

      beforeEach(() => {
        mutate = jest.fn().mockResolvedValue({
          data: {
            epicBoardCreate: {
              epicBoard: { id: 'gid://gitlab/Boards::EpicBoard/123', webPath: 'test-path' },
            },
          },
        });
      });

      it('does not call API if board name is empty', async () => {
        createComponent({ props: { canAdminBoard: true, currentPage: formType.new } });
        findInput().trigger('keyup.enter', { metaKey: true });

        await waitForPromises();

        expect(mutate).not.toHaveBeenCalled();
      });

      it('calls a correct GraphQL mutation and updates board on state', async () => {
        createComponent({ props: { canAdminBoard: true, currentPage: formType.new } });
        fillForm();

        await waitForPromises();

        expect(mutate).toHaveBeenCalledWith({
          mutation: createEpicBoardMutation,
          variables: {
            input: expect.objectContaining({
              name: 'test',
            }),
          },
        });

        await waitForPromises();
        expect(setBoardMock).toHaveBeenCalledTimes(1);
      });

      it('sets error if GraphQL mutation fails', async () => {
        mutate = jest.fn().mockRejectedValue('Houston, we have a problem');
        createComponent({ props: { canAdminBoard: true, currentPage: formType.new } });
        fillForm();

        await waitForPromises();

        expect(mutate).toHaveBeenCalled();

        await waitForPromises();
        expect(setBoardMock).not.toHaveBeenCalled();
        expect(setErrorMock).toHaveBeenCalled();
      });
    });
  });

  describe('when editing a scoped issue board', () => {
    beforeEach(() => {
      createStore();
    });

    it('should use global ids for assignee, milestone and iteration when calling GraphQL mutation', async () => {
      mutate = jest.fn().mockResolvedValue({
        data: {
          updateBoard: { board: { id: 'gid://gitlab/Board/321' } },
        },
      });

      createComponent({
        props: {
          currentBoard: {
            ...currentBoard,
            assignee: {
              id: 1,
            },
            milestone: {
              id: 'gid://gitlab/Milestone/2',
            },
            iteration: {
              id: 'gid://gitlab/Iteration/3',
            },
          },
          canAdminBoard: true,
          currentPage: formType.edit,
          scopedIssueBoardFeatureEnabled: true,
        },
        isIssueBoard: true,
        isEpicBoard: false,
      });

      findInput().trigger('keyup.enter', { metaKey: true });

      await waitForPromises();

      expect(mutate).toHaveBeenCalledWith({
        mutation: updateBoardMutation,
        variables: {
          input: expect.objectContaining({
            id: currentBoard.id,
            assigneeId: 'gid://gitlab/User/1',
            milestoneId: 'gid://gitlab/Milestone/2',
            iterationId: 'gid://gitlab/Iteration/3',
          }),
        },
      });
    });

    it('should send iterationCadenceId', async () => {
      mutate = jest.fn().mockResolvedValue({
        data: {
          updateBoard: { board: { id: 'gid://gitlab/Board/321' } },
        },
      });

      createComponent({
        props: {
          currentBoard: {
            ...currentBoard,
            assignee: {
              id: 1,
            },
            milestone: {
              id: 'gid://gitlab/Milestone/2',
            },
            iteration: {
              id: 'gid://gitlab/Iteration/3',
            },
            iterationCadenceId: 'gid://gitlab/Iterations::Cadence/4',
          },
          canAdminBoard: true,
          currentPage: formType.edit,
          scopedIssueBoardFeatureEnabled: true,
        },
        iterationCadences: true,
        isIssueBoard: true,
        isEpicBoard: false,
      });

      findInput().trigger('keyup.enter', { metaKey: true });

      await waitForPromises();

      expect(mutate).toHaveBeenCalledWith({
        mutation: updateBoardMutation,
        variables: {
          input: expect.objectContaining({
            id: currentBoard.id,
            assigneeId: 'gid://gitlab/User/1',
            milestoneId: 'gid://gitlab/Milestone/2',
            iterationId: 'gid://gitlab/Iteration/3',
            iterationCadenceId: 'gid://gitlab/Iterations::Cadence/4',
          }),
        },
      });
    });
  });

  describe('when editing an epic board', () => {
    beforeEach(() => {
      createStore();
    });

    it('calls GraphQL mutation with correct parameters', async () => {
      mutate = jest.fn().mockResolvedValue({
        data: {
          epicBoardUpdate: {
            epicBoard: { id: currentEpicBoard.id, webPath: 'test-path' },
          },
        },
      });
      createComponent({
        props: {
          canAdminBoard: true,
          currentPage: formType.edit,
          currentBoard: currentEpicBoard,
        },
      });

      findInput().trigger('keyup.enter', { metaKey: true });

      await waitForPromises();

      expect(mutate).toHaveBeenCalledWith({
        mutation: updateEpicBoardMutation,
        variables: {
          input: expect.objectContaining({
            id: currentEpicBoard.id,
          }),
        },
      });

      await waitForPromises();
      expect(setBoardMock).toHaveBeenCalledTimes(1);
    });

    it('sets error if GraphQL mutation fails', async () => {
      mutate = jest.fn().mockRejectedValue('Houston, we have a problem');
      createComponent({
        props: {
          canAdminBoard: true,
          currentPage: formType.edit,
          currentBoard: currentEpicBoard,
        },
      });
      findInput().trigger('keyup.enter', { metaKey: true });

      await waitForPromises();

      expect(mutate).toHaveBeenCalled();

      await waitForPromises();
      expect(setBoardMock).not.toHaveBeenCalled();
      expect(setErrorMock).toHaveBeenCalled();
    });
  });

  describe('when deleting an epic board', () => {
    beforeEach(() => {
      createStore();
    });

    it('passes correct primary action text and variant', () => {
      createComponent({
        props: {
          canAdminBoard: true,
          currentPage: formType.delete,
          currentBoard: currentEpicBoard,
        },
      });
      expect(findModalActionPrimary().text).toBe('Delete');
      expect(findModalActionPrimary().attributes[0].variant).toBe('danger');
    });

    it('renders delete confirmation message', () => {
      createComponent({
        props: {
          canAdminBoard: true,
          currentPage: formType.delete,
          currentBoard: currentEpicBoard,
        },
      });
      expect(findDeleteConfirmation().exists()).toBe(true);
    });

    it('calls a correct GraphQL mutation and redirects to correct page after deleting board', async () => {
      mutate = jest.fn().mockResolvedValue({});
      createComponent({
        props: {
          canAdminBoard: true,
          currentPage: formType.delete,
          currentBoard: currentEpicBoard,
        },
      });
      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(mutate).toHaveBeenCalledWith({
        mutation: destroyEpicBoardMutation,
        variables: {
          id: currentEpicBoard.id,
        },
      });

      await waitForPromises();
      expect(visitUrl).toHaveBeenCalledWith('root');
    });

    it('shows a GlAlert if GraphQL mutation fails', async () => {
      mutate = jest.fn().mockRejectedValue('Houston, we have a problem');
      createComponent({
        props: {
          canAdminBoard: true,
          currentPage: formType.delete,
          currentBoard: currentEpicBoard,
        },
      });
      jest.spyOn(wrapper.vm, 'setError').mockImplementation(() => {});
      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(mutate).toHaveBeenCalled();

      await waitForPromises();
      expect(visitUrl).not.toHaveBeenCalled();
      expect(wrapper.vm.setError).toHaveBeenCalled();
    });
  });
});
