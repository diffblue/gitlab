import { shallowMount } from '@vue/test-utils';
import { GlCard } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import RelatedIssues from 'ee/vulnerabilities/components/related_issues.vue';
import { createAlert } from '~/alert';
import { TYPE_ISSUE } from '~/issues/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_SERVICE_UNAVAILABLE } from '~/lib/utils/http_status';
import * as urlUtility from '~/lib/utils/url_utility';
import RelatedIssuesBlock from '~/related_issues/components/related_issues_block.vue';
import { PathIdSeparator } from '~/related_issues/constants';

jest.mock('~/alert');

const mockAxios = new MockAdapter(axios);

describe('Vulnerability related issues component', () => {
  let wrapper;

  const propsData = {
    endpoint: 'endpoint',
    projectPath: 'project/path',
    helpPath: 'help/path',
    canModifyRelatedIssues: true,
  };

  const vulnerabilityId = 5131;
  const newIssueUrl = '/new/issue';
  const projectFingerprint = 'project-fingerprint';
  const issueTrackingHelpPath = '/help/issue/tracking';
  const permissionsHelpPath = '/help/permissions';
  const reportType = 'vulnerability';
  const issue1 = { id: 3, vulnerabilityLinkId: 987 };
  const issue2 = { id: 25, vulnerabilityLinkId: 876 };

  const createWrapper = ({ data = {}, provide = {}, stubs = {} } = {}) => {
    wrapper = shallowMount(RelatedIssues, {
      propsData,
      data: () => data,
      provide: {
        vulnerabilityId,
        projectFingerprint,
        newIssueUrl,
        reportType,
        issueTrackingHelpPath,
        permissionsHelpPath,
        ...provide,
      },
      stubs: {
        GlCard,
        ...stubs,
      },
    });
    // Need this special check because RelatedIssues creates the store and uses its state in the data function, so we
    // need to set the state of the store, not replace the state property.
    if (data.state) {
      wrapper.vm.store.state = data.state;
    }
  };

  const relatedIssuesBlock = () => wrapper.findComponent(RelatedIssuesBlock);
  const blockProp = (prop) => relatedIssuesBlock().props(prop);
  const blockEmit = (eventName, data) => relatedIssuesBlock().vm.$emit(eventName, data);
  const findCreateIssueButton = () => wrapper.findComponent({ ref: 'createIssue' });

  afterEach(() => {
    mockAxios.reset();
  });

  it('passes the expected props to the RelatedIssuesBlock component', () => {
    window.gl = { GfmAutoComplete: { dataSources: {} } };
    const data = {
      isFetching: true,
      isSubmitting: true,
      isFormVisible: true,
      inputValue: 'input value',
      state: {
        relatedIssues: [{}, {}, {}],
        pendingReferences: ['#1', '#2', '#3'],
      },
    };

    createWrapper({ data });

    expect(relatedIssuesBlock().props()).toMatchObject({
      helpPath: propsData.helpPath,
      isFetching: data.isFetching,
      isSubmitting: data.isSubmitting,
      relatedIssues: data.state.relatedIssues,
      canAdmin: propsData.canModifyRelatedIssues,
      pendingReferences: data.state.pendingReferences,
      isFormVisible: data.isFormVisible,
      inputValue: data.inputValue,
      autoCompleteSources: window.gl.GfmAutoComplete.dataSources,
      issuableType: TYPE_ISSUE,
      pathIdSeparator: PathIdSeparator.Issue,
      showCategorizedIssues: false,
    });
  });

  describe('fetch related issues', () => {
    it('fetches related issues when the component is created', async () => {
      mockAxios.onGet(propsData.endpoint).replyOnce(HTTP_STATUS_OK, [issue1, issue2]);
      createWrapper();
      await axios.waitForAll();

      expect(mockAxios.history.get).toHaveLength(1);
      expect(blockProp('relatedIssues')).toMatchObject([issue1, issue2]);
    });

    it('shows an error message if the fetch fails', async () => {
      mockAxios.onGet(propsData.endpoint).replyOnce(HTTP_STATUS_SERVICE_UNAVAILABLE);
      createWrapper();
      await axios.waitForAll();

      expect(blockProp('relatedIssues')).toEqual([]);
      expect(createAlert).toHaveBeenCalledTimes(1);
    });
  });

  describe('add related issue', () => {
    beforeEach(() => {
      mockAxios.onGet(propsData.endpoint).replyOnce(HTTP_STATUS_OK, []);
      createWrapper({ data: { isFormVisible: true } });
    });

    it('adds related issue with vulnerabilityLinkId populated', async () => {
      mockAxios
        .onPost(propsData.endpoint)
        .replyOnce(HTTP_STATUS_OK, { issue: {}, id: issue1.vulnerabilityLinkId });
      blockEmit('addIssuableFormSubmit', { pendingReferences: '#1' });
      await axios.waitForAll();

      expect(mockAxios.history.post).toHaveLength(1);
      const requestData = JSON.parse(mockAxios.history.post[0].data);
      expect(requestData.target_issue_iid).toBe('1');
      expect(requestData.target_project_id).toBe(propsData.projectPath);
      expect(blockProp('relatedIssues')).toHaveLength(1);
      expect(blockProp('relatedIssues')[0].vulnerabilityLinkId).toBe(issue1.vulnerabilityLinkId);
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('adds multiple issues', async () => {
      mockAxios.onPost(propsData.endpoint).reply(HTTP_STATUS_OK, { issue: {} });
      blockEmit('addIssuableFormSubmit', { pendingReferences: '#1 #2 #3' });
      await axios.waitForAll();

      expect(mockAxios.history.post).toHaveLength(3);
      expect(blockProp('relatedIssues')).toHaveLength(3);
      expect(blockProp('isFormVisible')).toBe(false);
      expect(blockProp('inputValue')).toBe('');
    });

    it('adds only issues that returns issue', async () => {
      mockAxios
        .onPost(propsData.endpoint)
        .replyOnce(HTTP_STATUS_OK, { issue: {} })
        .onPost(propsData.endpoint)
        .replyOnce(HTTP_STATUS_SERVICE_UNAVAILABLE)
        .onPost(propsData.endpoint)
        .replyOnce(HTTP_STATUS_OK, { issue: {} })
        .onPost(propsData.endpoint)
        .replyOnce(HTTP_STATUS_SERVICE_UNAVAILABLE);
      blockEmit('addIssuableFormSubmit', { pendingReferences: '#1 #2 #3 #4' });
      await axios.waitForAll();

      expect(mockAxios.history.post).toHaveLength(4);
      expect(blockProp('relatedIssues')).toHaveLength(2);
      expect(blockProp('isFormVisible')).toBe(true);
      expect(blockProp('inputValue')).toBe('');
      expect(blockProp('pendingReferences')).toEqual(['#2', '#4']);
      expect(createAlert).toHaveBeenCalledTimes(1);
    });
  });

  describe('related issues form', () => {
    it.each`
      from     | to
      ${true}  | ${false}
      ${false} | ${true}
    `('toggles form visibility from $from to $to', async ({ from, to }) => {
      createWrapper({ data: { isFormVisible: from } });

      blockEmit('toggleAddRelatedIssuesForm');
      await nextTick();
      expect(blockProp('isFormVisible')).toBe(to);
    });

    it('resets form and hides it', async () => {
      createWrapper({
        data: {
          inputValue: 'some input value',
          isFormVisible: true,
          state: { pendingReferences: ['135', '246'] },
        },
      });
      blockEmit('addIssuableFormCancel');
      await nextTick();

      expect(blockProp('isFormVisible')).toBe(false);
      expect(blockProp('inputValue')).toBe('');
      expect(blockProp('pendingReferences')).toEqual([]);
    });
  });

  describe('pending references', () => {
    it('adds pending references', async () => {
      const pendingReferences = ['135', '246'];
      const untouchedRawReferences = ['357', '468'];
      const touchedReference = 'touchedReference';
      createWrapper({ data: { state: { pendingReferences } } });
      blockEmit('addIssuableFormInput', { untouchedRawReferences, touchedReference });
      await nextTick();

      expect(blockProp('pendingReferences')).toEqual(
        pendingReferences.concat(untouchedRawReferences),
      );
      expect(blockProp('inputValue')).toBe(touchedReference);
    });

    it('processes pending references', async () => {
      createWrapper();
      blockEmit('addIssuableFormBlur', '135 246');
      await nextTick();

      expect(blockProp('pendingReferences')).toEqual(['135', '246']);
      expect(blockProp('inputValue')).toBe('');
    });

    it('removes pending reference', async () => {
      createWrapper({ data: { state: { pendingReferences: ['135', '246', '357'] } } });
      blockEmit('pendingIssuableRemoveRequest', 1);
      await nextTick();

      expect(blockProp('pendingReferences')).toEqual(['135', '357']);
    });
  });

  describe('remove related issue', () => {
    beforeEach(async () => {
      mockAxios.onGet(propsData.endpoint).replyOnce(HTTP_STATUS_OK, [issue1, issue2]);
      createWrapper();
      await axios.waitForAll();
    });

    it('removes related issue', async () => {
      mockAxios
        .onDelete(`${propsData.endpoint}/${issue1.vulnerabilityLinkId}`)
        .replyOnce(HTTP_STATUS_OK);
      blockEmit('relatedIssueRemoveRequest', issue1.id);
      await axios.waitForAll();

      expect(mockAxios.history.delete).toHaveLength(1);
      expect(blockProp('relatedIssues')).toMatchObject([issue2]);
    });

    it('shows error message if related issue could not be removed', async () => {
      mockAxios
        .onDelete(`${propsData.endpoint}/${issue1.vulnerabilityLinkId}`)
        .replyOnce(HTTP_STATUS_SERVICE_UNAVAILABLE);
      blockEmit('relatedIssueRemoveRequest', issue1.id);
      await axios.waitForAll();

      expect(mockAxios.history.delete).toHaveLength(1);
      expect(blockProp('relatedIssues')).toMatchObject([issue1, issue2]);
      expect(createAlert).toHaveBeenCalledTimes(1);
    });
  });

  describe('when linked issue is already created', () => {
    beforeEach(() => {
      createWrapper({
        data: {
          isFetching: false,
          state: { relatedIssues: [issue1, { ...issue2, vulnerabilityLinkType: 'created' }] },
        },
        stubs: { RelatedIssuesBlock },
      });
    });

    it('does not display the create issue button', () => {
      expect(findCreateIssueButton().exists()).toBe(false);
    });
  });

  describe('when linked issue is not yet created', () => {
    let redirectToSpy;

    beforeEach(async () => {
      redirectToSpy = jest.spyOn(urlUtility, 'redirectTo').mockImplementation(() => {});
      mockAxios.onGet(propsData.endpoint).replyOnce(HTTP_STATUS_OK, [issue1, issue2]);
      createWrapper({ stubs: { RelatedIssuesBlock } });
      await axios.waitForAll();
    });

    it('displays the create issue button', () => {
      expect(findCreateIssueButton().exists()).toBe(true);
    });

    it('calls new issue endpoint on click', () => {
      findCreateIssueButton().vm.$emit('click');
      expect(redirectToSpy).toHaveBeenCalledWith(newIssueUrl, {
        params: { vulnerability_id: vulnerabilityId },
      });
    });
  });

  describe('when project issue tracking is disabled', () => {
    it('hides the "Create Issue" button', () => {
      createWrapper({
        provide: {
          newIssueUrl: undefined,
        },
      });

      expect(findCreateIssueButton().exists()).toBe(false);
    });
  });
});
