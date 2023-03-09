import { mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import SidebarIterationWidget from 'ee/sidebar/components/iteration/sidebar_iteration_widget.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { TYPE_ISSUE } from '~/issues/constants';
import groupIterationsQuery from 'ee/sidebar/queries/group_iterations.query.graphql';
import projectIssueIterationQuery from 'ee/sidebar/queries/project_issue_iteration.query.graphql';
import { IssuableAttributeType, issuableAttributesQueries } from 'ee/sidebar/constants';
import { getIterationPeriod } from 'ee/iterations/utils';
import {
  mockIssue,
  mockGroupIterationsResponse,
  mockIteration1,
  mockIteration2,
  mockCurrentIterationResponse1,
  mockCurrentIterationResponse2,
} from '../../mock_data';
import { clickEdit } from '../../helpers';

Vue.use(VueApollo);

describe('SidebarIterationWidget', () => {
  let wrapper;
  let mockApollo;

  const findCurrentIterationText = () => wrapper.findByTestId('select-iteration').text();
  const findIterationItemsTextAt = (at) => wrapper.findAllByTestId('iteration-items').at(at).text();
  const findIterationCadenceTitleAt = (at) =>
    wrapper.findAllByTestId('cadence-title').at(at).text();

  const createComponentWithApollo = async ({
    iterationCadences = false,
    currentIterationResponse = mockCurrentIterationResponse1,
  } = {}) => {
    mockApollo = createMockApollo([
      [groupIterationsQuery, jest.fn().mockResolvedValue(mockGroupIterationsResponse)],
      [projectIssueIterationQuery, jest.fn().mockResolvedValue(currentIterationResponse)],
    ]);

    wrapper = extendedWrapper(
      mount(SidebarIterationWidget, {
        provide: {
          glFeatures: { iterationCadences },
          issuableAttributesQueries,
          canUpdate: true,
        },
        apolloProvider: mockApollo,
        propsData: {
          workspacePath: mockIssue.projectPath,
          attrWorkspacePath: mockIssue.groupPath,
          iid: mockIssue.iid,
          issuableType: TYPE_ISSUE,
          issuableAttribute: IssuableAttributeType.Iteration,
        },
      }),
    );

    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  describe('when showing the current iteration (dropdown is closed)', () => {
    it('renders cadence title', async () => {
      await createComponentWithApollo({ iterationCadences: true });

      expect(findCurrentIterationText()).toContain(mockIteration1.iterationCadence.title);
    });

    it('renders just iteration period for iteration without title', async () => {
      await createComponentWithApollo({ iterationCadences: true });

      expect(findCurrentIterationText()).toContain(getIterationPeriod(mockIteration1));
    });

    it('renders iteration period with optional title for iteration with title', async () => {
      await createComponentWithApollo({
        iterationCadences: true,
        currentIterationResponse: mockCurrentIterationResponse2,
      });

      expect(findCurrentIterationText()).toContain(getIterationPeriod(mockIteration2));
      expect(findCurrentIterationText()).toContain(mockIteration2.title);
    });
  });

  describe('when listing iterations in the dropdown', () => {
    it('renders iterations with cadence names', async () => {
      await createComponentWithApollo({ iterationCadences: true });
      await clickEdit(wrapper);
      jest.runOnlyPendingTimers();
      await waitForPromises();

      // mockIteration1 has no title
      expect(findIterationCadenceTitleAt(0)).toContain(mockIteration1.iterationCadence.title);
      expect(findIterationItemsTextAt(0)).toContain(getIterationPeriod(mockIteration1));

      // mockIteration2 has a title
      expect(findIterationCadenceTitleAt(1)).toContain(mockIteration2.iterationCadence.title);
      expect(findIterationItemsTextAt(1)).toContain(getIterationPeriod(mockIteration2));
      expect(findIterationItemsTextAt(1)).toContain(mockIteration2.title);
    });
  });
});
