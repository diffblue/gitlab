import { GlDropdown, GlDropdownItem, GlFormInput } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import SidebarDropdownWidget from 'ee/sidebar/components/sidebar_dropdown_widget.vue';
import { IssuableAttributeType, issuableAttributesQueries } from 'ee/sidebar/constants';
import groupEpicsQuery from 'ee/sidebar/queries/group_epics.query.graphql';
import projectIssueEpicMutation from 'ee/sidebar/queries/project_issue_epic.mutation.graphql';
import projectIssueEpicQuery from 'ee/sidebar/queries/project_issue_epic.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import { IssuableType } from '~/issues/constants';
import { clickEdit, search } from '../helpers';

import {
  mockIssue,
  mockGroupEpicsResponse,
  noCurrentEpicResponse,
  mockEpicMutationResponse,
  mockEpic2,
  emptyGroupEpicsResponse,
} from '../mock_data';

jest.mock('~/flash');

describe('SidebarDropdownWidget', () => {
  let wrapper;
  let mockApollo;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAll(GlDropdownItem);
  const findDropdownItemWithText = (text) =>
    findAllDropdownItems().wrappers.find((x) => x.text() === text);
  const findSelectedAttribute = () => wrapper.findByTestId('select-epic');

  const createComponentWithApollo = async ({
    requestHandlers = [],
    groupEpicsSpy = jest.fn().mockResolvedValue(mockGroupEpicsResponse),
    currentEpicSpy = jest.fn().mockResolvedValue(noCurrentEpicResponse),
  } = {}) => {
    Vue.use(VueApollo);
    mockApollo = createMockApollo([
      [groupEpicsQuery, groupEpicsSpy],
      [projectIssueEpicQuery, currentEpicSpy],
      ...requestHandlers,
    ]);

    wrapper = extendedWrapper(
      mount(SidebarDropdownWidget, {
        provide: { canUpdate: true, issuableAttributesQueries },
        apolloProvider: mockApollo,
        propsData: {
          workspacePath: mockIssue.projectPath,
          attrWorkspacePath: mockIssue.groupPath,
          iid: mockIssue.iid,
          issuableType: IssuableType.Issue,
          issuableAttribute: IssuableAttributeType.Epic,
        },
        attachTo: document.body,
      }),
    );

    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with mock apollo', () => {
    let error;

    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException');
      error = new Error('mayday');
    });

    describe("when issuable type is 'issue'", () => {
      describe('when dropdown is expanded and user can edit', () => {
        let epicMutationSpy;
        beforeEach(async () => {
          epicMutationSpy = jest.fn().mockResolvedValue(mockEpicMutationResponse);

          await createComponentWithApollo({
            requestHandlers: [[projectIssueEpicMutation, epicMutationSpy]],
          });

          await clickEdit(wrapper);
        });

        it('renders the dropdown on clicking edit', async () => {
          expect(findDropdown().isVisible()).toBe(true);
        });

        it('focuses on the input when dropdown is shown', async () => {
          expect(document.activeElement).toEqual(wrapper.findComponent(GlFormInput).element);
        });

        describe('when currentAttribute is not equal to attribute id', () => {
          describe('when update is successful', () => {
            beforeEach(() => {
              findDropdownItemWithText(mockEpic2.title).vm.$emit('click');
            });

            it('calls setIssueAttribute mutation', () => {
              expect(epicMutationSpy).toHaveBeenCalledWith({
                iid: mockIssue.iid,
                attributeId: mockEpic2.id,
                fullPath: mockIssue.projectPath,
              });
            });

            it('sets the value returned from the mutation to currentAttribute', async () => {
              expect(findSelectedAttribute().text()).toBe(mockEpic2.title);
            });
          });
        });

        describe('epics', () => {
          let groupEpicsSpy;

          it('should call createFlash if epics query fails', async () => {
            await createComponentWithApollo({
              groupEpicsSpy: jest.fn().mockRejectedValue(error),
            });

            await clickEdit(wrapper);

            expect(createFlash).toHaveBeenCalledWith({
              message: 'Failed to fetch the epic for this issue. Please try again.',
              captureError: true,
              error: expect.any(Error),
            });
          });

          it('only fetches attributes when dropdown is opened', async () => {
            groupEpicsSpy = jest.fn().mockResolvedValueOnce(emptyGroupEpicsResponse);
            await createComponentWithApollo({ groupEpicsSpy });

            expect(groupEpicsSpy).not.toHaveBeenCalled();

            await clickEdit(wrapper);

            expect(groupEpicsSpy).toHaveBeenNthCalledWith(1, {
              fullPath: mockIssue.groupPath,
              sort: 'TITLE_ASC',
              state: 'opened',
            });
          });

          describe('when a user is searching epics', () => {
            const mockSearchTerm = 'foobar';

            beforeEach(async () => {
              groupEpicsSpy = jest.fn().mockResolvedValueOnce(emptyGroupEpicsResponse);
              await createComponentWithApollo({ groupEpicsSpy });

              await clickEdit(wrapper);
            });

            it('sends a groupEpics query with the entered search term "foo" and in TITLE param', async () => {
              await search(wrapper, mockSearchTerm);

              expect(groupEpicsSpy).toHaveBeenNthCalledWith(2, {
                fullPath: mockIssue.groupPath,
                sort: 'TITLE_ASC',
                state: 'opened',
                title: mockSearchTerm,
                in: 'TITLE',
              });
            });
          });

          describe('when a user is not searching', () => {
            beforeEach(async () => {
              groupEpicsSpy = jest.fn().mockResolvedValueOnce(emptyGroupEpicsResponse);
              await createComponentWithApollo({ groupEpicsSpy });

              await clickEdit(wrapper);
            });

            it('sends a groupEpics query with empty title and undefined in param', async () => {
              await waitForPromises();

              // Account for debouncing
              jest.runAllTimers();

              expect(groupEpicsSpy).toHaveBeenNthCalledWith(1, {
                fullPath: mockIssue.groupPath,
                sort: 'TITLE_ASC',
                state: 'opened',
              });
            });

            it('sends a groupEpics query for an IID with the entered search term "&1"', async () => {
              await search(wrapper, '&1');

              expect(groupEpicsSpy).toHaveBeenNthCalledWith(2, {
                fullPath: mockIssue.groupPath,
                iidStartsWith: '1',
                sort: 'TITLE_ASC',
                state: 'opened',
              });
            });
          });
        });
      });

      describe('currentAttributes', () => {
        it('should call createFlash if currentAttributes query fails', async () => {
          await createComponentWithApollo({
            currentEpicSpy: jest.fn().mockRejectedValue(error),
          });

          expect(createFlash).toHaveBeenCalledWith({
            message: 'An error occurred while fetching the assigned epic of the selected issue.',
            captureError: true,
            error: expect.any(Error),
          });
        });
      });
    });
  });
});
