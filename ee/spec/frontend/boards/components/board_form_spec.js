import { GlModal } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoardForm from 'ee/boards/components/board_form.vue';
import createEpicBoardMutation from 'ee/boards/graphql/epic_board_create.mutation.graphql';
import destroyEpicBoardMutation from 'ee/boards/graphql/epic_board_destroy.mutation.graphql';
import updateEpicBoardMutation from 'ee/boards/graphql/epic_board_update.mutation.graphql';
import updateMutation from '~/boards/graphql/board_update.mutation.graphql';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { formType } from '~/boards/constants';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn().mockName('visitUrlMock'),
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
  let requestHandlers;
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

  const defaultHandlers = {
    create: jest.fn().mockResolvedValue({}),
    destroy: jest.fn().mockResolvedValue({}),
    update: jest.fn().mockResolvedValue({}),
  };

  const createMockApolloProvider = (handlers) => {
    Vue.use(VueApollo);

    requestHandlers = handlers;

    return createMockApollo([
      [createEpicBoardMutation, handlers.create],
      [updateEpicBoardMutation, handlers.update],
      [destroyEpicBoardMutation, handlers.destroy],
      [updateMutation, handlers.updateBoard],
    ]);
  };

  const createComponent = ({
    props,
    iterationCadences = false,
    isIssueBoard = false,
    isEpicBoard = true,
    handlers = defaultHandlers,
  } = {}) => {
    const apolloProvider = createMockApolloProvider(handlers);

    wrapper = shallowMountExtended(BoardForm, {
      apolloProvider,
      propsData: { ...defaultProps, ...props },
      provide: {
        boardBaseUrl: 'root',
        glFeatures: { iterationCadences },
        isIssueBoard,
        isEpicBoard,
        isGroupBoard: true,
        isProjectBoard: false,
      },
      attachTo: document.body,
      store,
    });
  };

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
        expect(findModalActionPrimary().attributes.variant).toBe('confirm');
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

      it('does not call API if board name is empty', async () => {
        createComponent({
          props: { canAdminBoard: true, currentPage: formType.new },
          handlers: {
            ...defaultHandlers,
            create: jest.fn().mockResolvedValue({
              data: {
                epicBoardCreate: {
                  epicBoard: { id: 'gid://gitlab/Boards::EpicBoard/123', webPath: 'test-path' },
                },
              },
            }),
          },
        });
        findInput().trigger('keyup.enter', { metaKey: true });

        await waitForPromises();

        expect(requestHandlers.create).not.toHaveBeenCalled();
      });

      it('calls a correct GraphQL mutation and updates board on state', async () => {
        createComponent({
          props: { canAdminBoard: true, currentPage: formType.new },
          handlers: {
            ...defaultHandlers,
            create: jest.fn().mockResolvedValue({
              data: {
                epicBoardCreate: {
                  epicBoard: { id: 'gid://gitlab/Boards::EpicBoard/123', webPath: 'test-path' },
                  errors: [],
                },
              },
            }),
          },
        });
        fillForm();

        await waitForPromises();
        expect(requestHandlers.create).toHaveBeenCalledWith({
          input: {
            groupPath: '',
            hideBacklogList: false,
            hideClosedList: false,
            labelIds: [],
            name: 'test',
            projectPath: undefined,
          },
        });

        await waitForPromises();
        expect(setBoardMock).toHaveBeenCalledTimes(1);
      });

      it('sets error if GraphQL mutation fails', async () => {
        createComponent({
          props: { canAdminBoard: true, currentPage: formType.new },
          handlers: {
            create: jest.fn().mockRejectedValue({}),
          },
        });
        fillForm();

        await waitForPromises();

        expect(requestHandlers.create).toHaveBeenCalled();

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
        handlers: {
          updateBoard: jest.fn().mockResolvedValue({
            data: {
              updateBoard: {
                board: { id: 'gid://gitlab/Board/321' },
                errors: [],
              },
            },
          }),
        },
      });

      findInput().trigger('keyup.enter', { metaKey: true });

      await waitForPromises();

      expect(requestHandlers.updateBoard).toHaveBeenCalledWith({
        input: {
          hideBacklogList: false,
          hideClosedList: false,
          id: currentBoard.id,
          iterationCadenceId: null,
          assigneeId: 'gid://gitlab/User/1',
          milestoneId: 'gid://gitlab/Milestone/2',
          labelIds: [],
          iterationId: 'gid://gitlab/Iteration/3',
          name: 'test',
          weight: null,
        },
      });
    });

    it('should send iterationCadenceId', async () => {
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
        handlers: {
          updateBoard: jest.fn().mockResolvedValue({
            data: {
              updateBoard: {
                board: { id: 'gid://gitlab/Board/321' },
                errors: [],
              },
            },
          }),
        },
      });

      findInput().trigger('keyup.enter', { metaKey: true });

      await waitForPromises();

      expect(requestHandlers.updateBoard).toHaveBeenCalledWith({
        input: {
          assigneeId: 'gid://gitlab/User/1',
          hideBacklogList: false,
          hideClosedList: false,
          id: currentBoard.id,
          iterationCadenceId: 'gid://gitlab/Iterations::Cadence/4',
          iterationId: 'gid://gitlab/Iteration/3',
          labelIds: [],
          milestoneId: 'gid://gitlab/Milestone/2',
          name: 'test',
          weight: null,
        },
      });
    });
  });

  describe('when editing an epic board', () => {
    beforeEach(() => {
      createStore();
    });

    it('calls GraphQL mutation with correct parameters', async () => {
      createComponent({
        props: {
          canAdminBoard: true,
          currentPage: formType.edit,
          currentBoard: currentEpicBoard,
        },
        handlers: {
          update: jest.fn().mockResolvedValue({
            data: {
              epicBoardUpdate: {
                epicBoard: { id: currentEpicBoard.id, webPath: 'test-path' },
                errors: [],
              },
            },
          }),
        },
      });

      findInput().trigger('keyup.enter', { metaKey: true });

      await waitForPromises();

      expect(requestHandlers.update).toHaveBeenCalledWith({
        input: {
          hideBacklogList: false,
          hideClosedList: false,
          id: currentEpicBoard.id,
          labelIds: [],
          name: 'test',
        },
      });

      await waitForPromises();
      expect(setBoardMock).toHaveBeenCalledTimes(1);
    });

    it('sets error if GraphQL mutation fails', async () => {
      createComponent({
        props: {
          canAdminBoard: true,
          currentPage: formType.edit,
          currentBoard: currentEpicBoard,
        },
        handlers: {
          update: jest.fn().mockRejectedValue({}),
        },
      });
      findInput().trigger('keyup.enter', { metaKey: true });

      await waitForPromises();

      expect(requestHandlers.update).toHaveBeenCalled();

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
      expect(findModalActionPrimary().attributes.variant).toBe('danger');
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
      createComponent({
        props: {
          canAdminBoard: true,
          currentPage: formType.delete,
          currentBoard: currentEpicBoard,
        },
        handlers: {
          destroy: jest.fn().mockResolvedValue({
            data: {
              destroyEpicBoard: {
                epicBoard: { id: '1' },
              },
            },
          }),
        },
      });
      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(requestHandlers.destroy).toHaveBeenCalledWith({
        id: currentEpicBoard.id,
      });

      await waitForPromises();
      expect(visitUrl).toHaveBeenCalledWith('root');
    });

    it('shows a GlAlert if GraphQL mutation fails', async () => {
      createComponent({
        props: {
          canAdminBoard: true,
          currentPage: formType.delete,
          currentBoard: currentEpicBoard,
        },
        handlers: { destroy: jest.fn().mockRejectedValue({}) },
      });

      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(requestHandlers.destroy).toHaveBeenCalled();

      await waitForPromises();
      expect(visitUrl).not.toHaveBeenCalled();
      expect(setErrorMock).toHaveBeenCalled();
    });
  });
});
