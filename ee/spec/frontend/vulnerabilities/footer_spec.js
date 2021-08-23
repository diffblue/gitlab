import { GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Api from 'ee/api';
import vulnerabilityDiscussionsQuery from 'ee/security_dashboard/graphql/queries/vulnerability_discussions.query.graphql';
import MergeRequestNote from 'ee/vue_shared/security_reports/components/merge_request_note.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';
import VulnerabilityFooter from 'ee/vulnerabilities/components/footer.vue';
import GenericReportSection from 'ee/vulnerabilities/components/generic_report/report_section.vue';
import HistoryEntry from 'ee/vulnerabilities/components/history_entry.vue';
import RelatedIssues from 'ee/vulnerabilities/components/related_issues.vue';
import RelatedJiraIssues from 'ee/vulnerabilities/components/related_jira_issues.vue';
import StatusDescription from 'ee/vulnerabilities/components/status_description.vue';
import { VULNERABILITY_STATES } from 'ee/vulnerabilities/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import initUserPopovers from '~/user_popovers';

const mockAxios = new MockAdapter(axios);
jest.mock('~/flash');
jest.mock('~/user_popovers');

Vue.use(VueApollo);

describe('Vulnerability Footer', () => {
  let wrapper;

  const vulnerability = {
    id: 1,
    notesUrl: '/notes',
    project: {
      fullPath: '/root/security-reports',
      fullName: 'Administrator / Security Reports',
    },
    canModifyRelatedIssues: true,
    relatedIssuesHelpPath: 'help/path',
    hasMr: false,
    pipeline: {},
  };

  let discussion1;
  let discussion2;
  let notes;

  const discussionsSuccessHandler = (nodes) =>
    jest.fn().mockResolvedValue({
      data: {
        vulnerability: {
          id: `gid://gitlab/Vulnerability/${vulnerability.id}`,
          discussions: {
            nodes,
          },
        },
      },
    });

  const discussionsErrorHandler = () =>
    jest.fn().mockRejectedValue({
      errors: [{ message: 'Something went wrong' }],
    });

  const createNotesRequest = (notesArray, statusCode = 200) => {
    return mockAxios
      .onGet(vulnerability.notesUrl)
      .replyOnce(statusCode, { notes: notesArray }, { date: Date.now() });
  };

  const createWrapper = ({ properties, discussionsHandler, mountOptions } = {}) => {
    createNotesRequest(notes);

    wrapper = shallowMountExtended(VulnerabilityFooter, {
      propsData: { vulnerability: { ...vulnerability, ...properties } },
      apolloProvider: createMockApollo([[vulnerabilityDiscussionsQuery, discussionsHandler]]),
      ...mountOptions,
    });
  };

  const createWrapperWithDiscussions = (props) => {
    createWrapper({
      ...props,
      discussionsHandler: discussionsSuccessHandler([discussion1, discussion2]),
    });
  };

  const findDiscussions = () => wrapper.findAllComponents(HistoryEntry);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findMergeRequestNote = () => wrapper.findComponent(MergeRequestNote);
  const findRelatedIssues = () => wrapper.findComponent(RelatedIssues);
  const findRelatedJiraIssues = () => wrapper.findComponent(RelatedJiraIssues);

  beforeEach(() => {
    discussion1 = {
      id: 'gid://gitlab/Discussion/7b4aa2d000ec81ba374a29b3ca3ee4c5f274f9ab',
      replyId: 'gid://gitlab/Discussion/7b4aa2d000ec81ba374a29b3ca3ee4c5f274f9ab',
    };

    discussion2 = {
      id: 'gid://gitlab/Discussion/0656f86109dc755c99c288c54d154b9705aaa796',
      replyId: 'gid://gitlab/Discussion/0656f86109dc755c99c288c54d154b9705aaa796',
    };

    notes = [
      { id: 100, note: 'some note', discussion_id: discussion1.id },
      { id: 200, note: 'another note', discussion_id: discussion2.id },
    ];
  });

  afterEach(() => {
    wrapper.destroy();
    mockAxios.reset();
  });

  describe('discussions and notes', () => {
    const createWrapperAndFetchNotes = async () => {
      createWrapperWithDiscussions();
      await axios.waitForAll();
      expect(findDiscussions()).toHaveLength(2);
      expect(findDiscussions().at(0).props('discussion').notes).toHaveLength(1);
    };

    const makePollRequest = async () => {
      wrapper.vm.poll.makeRequest();
      await axios.waitForAll();
    };

    it('displays a loading spinner while fetching discussions', async () => {
      createWrapperWithDiscussions();
      expect(findDiscussions().exists()).toBe(false);
      expect(findLoadingIcon().exists()).toBe(true);
      await axios.waitForAll();
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('fetches discussions and notes on mount', async () => {
      await createWrapperAndFetchNotes();

      expect(findDiscussions().at(0).props()).toEqual({
        discussion: { ...discussion1, notes: [convertObjectPropsToCamelCase(notes[0])] },
        notesUrl: vulnerability.notesUrl,
      });

      expect(findDiscussions().at(1).props()).toEqual({
        discussion: { ...discussion2, notes: [convertObjectPropsToCamelCase(notes[1])] },
        notesUrl: vulnerability.notesUrl,
      });
    });

    it('calls initUserPopovers when the component is updated', async () => {
      createWrapperWithDiscussions();
      expect(initUserPopovers).not.toHaveBeenCalled();
      await axios.waitForAll();
      expect(initUserPopovers).toHaveBeenCalled();
    });

    it('shows an error the discussions could not be retrieved', async () => {
      createWrapper({ discussionsHandler: discussionsErrorHandler() });
      await waitForPromises();
      expect(createFlash).toHaveBeenCalledWith({
        message:
          'Something went wrong while trying to retrieve the vulnerability history. Please try again later.',
      });
    });

    it('adds a new note to an existing discussion if the note does not exist', async () => {
      await createWrapperAndFetchNotes();

      // Fetch a new note
      const note = { id: 101, note: 'new note', discussion_id: discussion1.id };
      createNotesRequest([note]);
      await makePollRequest();

      expect(findDiscussions()).toHaveLength(2);
      expect(findDiscussions().at(0).props('discussion').notes[1].note).toBe(note.note);
    });

    it('updates an existing note if it already exists', async () => {
      await createWrapperAndFetchNotes();

      const note = { ...notes[0], note: 'updated note' };
      createNotesRequest([note]);
      await makePollRequest();

      expect(findDiscussions()).toHaveLength(2);
      expect(findDiscussions().at(0).props('discussion').notes).toHaveLength(1);
      expect(findDiscussions().at(0).props('discussion').notes[0].note).toBe(note.note);
    });

    it('creates a new discussion with a new note if the discussion does not exist', async () => {
      await createWrapperAndFetchNotes();

      const note = {
        id: 300,
        note: 'new note on a new discussion',
        discussion_id: 'new-discussion-id',
      };

      createNotesRequest([note]);
      await makePollRequest();

      expect(findDiscussions()).toHaveLength(3);
      expect(findDiscussions().at(2).props('discussion').notes).toHaveLength(1);
      expect(findDiscussions().at(2).props('discussion').notes[0].note).toBe(note.note);
    });

    it('shows an error if the notes poll fails', async () => {
      await createWrapperAndFetchNotes();

      createNotesRequest([], 500);
      await makePollRequest();

      expect(createFlash).toHaveBeenCalledWith({
        message: 'Something went wrong while fetching latest comments.',
      });
    });

    it('emits the vulnerability-state-change event when the system note is new', async () => {
      await createWrapperAndFetchNotes();

      const handler = jest.fn();
      wrapper.vm.$on('vulnerability-state-change', handler);

      const note = { system: true, id: 1, discussion_id: 'some-new-discussion-id' };
      createNotesRequest([note]);
      await makePollRequest();

      expect(handler).toHaveBeenCalledTimes(1);
    });
  });

  describe('solution card', () => {
    it('does show solution card when there is one', () => {
      const properties = { remediations: [{ diff: [{}] }], solution: 'some solution' };
      createWrapper({ properties, discussionsHandler: discussionsSuccessHandler([]) });

      expect(wrapper.find(SolutionCard).exists()).toBe(true);
      expect(wrapper.find(SolutionCard).props()).toEqual({
        solution: properties.solution,
        remediation: properties.remediations[0],
        hasDownload: true,
        hasMr: vulnerability.hasMr,
      });
    });

    it('does not show solution card when there is not one', () => {
      createWrapper();
      expect(wrapper.find(SolutionCard).exists()).toBe(false);
    });
  });

  describe('merge request note', () => {
    it('does not show merge request note when a merge request does not exist for the vulnerability', () => {
      createWrapper();
      expect(findMergeRequestNote().exists()).toBe(false);
    });

    it('shows merge request note when a merge request exists for the vulnerability', () => {
      // The object itself does not matter, we just want to make sure it's passed to the issue note.
      const mergeRequestFeedback = {};

      createWrapper({ properties: { mergeRequestFeedback } });
      expect(findMergeRequestNote().exists()).toBe(true);
      expect(findMergeRequestNote().props('feedback')).toBe(mergeRequestFeedback);
    });
  });

  describe('related issues', () => {
    it('has the correct props', () => {
      const endpoint = Api.buildUrl(Api.vulnerabilityIssueLinksPath).replace(
        ':id',
        vulnerability.id,
      );

      createWrapper();

      expect(findRelatedIssues().exists()).toBe(true);
      expect(findRelatedIssues().props()).toMatchObject({
        endpoint,
        canModifyRelatedIssues: vulnerability.canModifyRelatedIssues,
        projectPath: vulnerability.project.fullPath,
        helpPath: vulnerability.relatedIssuesHelpPath,
      });
    });
  });

  describe('related jira issues', () => {
    describe.each`
      createJiraIssueUrl | shouldShowRelatedJiraIssues
      ${'http://foo'}    | ${true}
      ${''}              | ${false}
    `(
      'with "createJiraIssueUrl" set to "$createJiraIssueUrl"',
      ({ createJiraIssueUrl, shouldShowRelatedJiraIssues }) => {
        beforeEach(() => {
          createWrapper({
            mountOptions: {
              provide: {
                createJiraIssueUrl,
              },
            },
          });
        });

        it(`${
          shouldShowRelatedJiraIssues ? 'should' : 'should not'
        } show related Jira issues`, () => {
          expect(findRelatedJiraIssues().exists()).toBe(shouldShowRelatedJiraIssues);
        });
      },
    );
  });

  describe('detection note', () => {
    const detectionNote = () => wrapper.find('[data-testid="detection-note"]');
    const statusDescription = () => wrapper.find(StatusDescription);
    const vulnerabilityStates = Object.keys(VULNERABILITY_STATES);

    it.each(vulnerabilityStates)(
      `shows detection note when vulnerability state is '%s'`,
      (state) => {
        createWrapper({ properties: { state } });

        expect(detectionNote().exists()).toBe(true);
        expect(statusDescription().props('vulnerability')).toEqual({
          state: 'detected',
          pipeline: vulnerability.pipeline,
        });
      },
    );
  });

  describe('generic report', () => {
    const mockDetails = { foo: { type: 'bar' } };

    const genericReportSection = () => wrapper.findComponent(GenericReportSection);

    describe('when a vulnerability contains a details property', () => {
      beforeEach(() => {
        createWrapper({ properties: { details: mockDetails } });
      });

      it('renders the report section', () => {
        expect(genericReportSection().exists()).toBe(true);
      });

      it('passes the correct props to the report section', () => {
        expect(genericReportSection().props()).toMatchObject({
          details: mockDetails,
        });
      });
    });

    describe('when a vulnerability does not contain a details property', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('does not render the report section', () => {
        expect(genericReportSection().exists()).toBe(false);
      });
    });
  });
});
