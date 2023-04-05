import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import VueApollo from 'vue-apollo';
import Api from 'ee/api';
import vulnerabilityStateMutations from 'ee/security_dashboard/graphql/mutate_vulnerability_state';
import SplitButton from 'ee/vue_shared/security_reports/components/split_button.vue';
import StatusBadge from 'ee/vue_shared/security_reports/components/status_badge.vue';
import Header from 'ee/vulnerabilities/components/header.vue';
import ResolutionAlert from 'ee/vulnerabilities/components/resolution_alert.vue';
import StatusDescription from 'ee/vulnerabilities/components/status_description.vue';
import VulnerabilityStateDropdownDeprecated from 'ee/vulnerabilities/components/vulnerability_state_dropdown_deprecated.vue';
import { FEEDBACK_TYPES, VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import UsersMockHelper from 'helpers/user_mock_data_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import download from '~/lib/utils/downloader';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import * as urlUtility from '~/lib/utils/url_utility';
import { getVulnerabilityStatusMutationResponse } from './mock_data';

Vue.use(VueApollo);

const vulnerabilityStateEntries = Object.entries(VULNERABILITY_STATE_OBJECTS);
const mockAxios = new MockAdapter(axios);
jest.mock('~/alert');
jest.mock('~/lib/utils/downloader');

describe('Vulnerability Header', () => {
  let wrapper;

  const defaultVulnerability = {
    id: 1,
    createdAt: new Date().toISOString(),
    reportType: 'sast',
    state: 'detected',
    createMrUrl: '/create_mr_url',
    newIssueUrl: '/new_issue_url',
    projectFingerprint: 'abc123',
    uuid: 'xxxxxxxx-xxxx-5xxx-xxxx-xxxxxxxxxxxx',
    pipeline: {
      id: 2,
      createdAt: new Date().toISOString(),
      url: 'pipeline_url',
      sourceBranch: 'main',
    },
    description: 'description',
    identifiers: 'identifiers',
    links: 'links',
    location: 'location',
    name: 'name',
    mergeRequestLinks: [],
    stateTransitions: [],
  };

  const diff = 'some diff to download';

  const getVulnerability = ({
    shouldShowMergeRequestButton,
    shouldShowDownloadPatchButton = true,
  }) => ({
    remediations: shouldShowMergeRequestButton ? [{ diff }] : null,
    state: shouldShowDownloadPatchButton ? 'detected' : 'resolved',
    mergeRequestLinks: shouldShowMergeRequestButton ? [] : [{}],
    mergeRequestFeedback: shouldShowMergeRequestButton ? null : {},
  });

  const createApolloProvider = (...queries) => {
    return createMockApollo([...queries]);
  };

  const createRandomUser = () => {
    const user = UsersMockHelper.createRandomUser();
    const url = Api.buildUrl(Api.userPath).replace(':id', user.id);
    mockAxios.onGet(url).replyOnce(HTTP_STATUS_OK, user);

    return user;
  };

  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findStatusBadge = () => wrapper.findComponent(StatusBadge);
  const findSplitButton = () => wrapper.findComponent(SplitButton);
  const findResolutionAlert = () => wrapper.findComponent(ResolutionAlert);
  const findStatusDescription = () => wrapper.findComponent(StatusDescription);

  // Helpers
  const changeStatus = (action) => {
    const dropdown = wrapper.findComponent(VulnerabilityStateDropdownDeprecated);
    dropdown.vm.$emit('change', { action });
  };

  const createWrapper = ({
    vulnerability = {},
    apolloProvider,
    deprecateVulnerabilitiesFeedback = true,
  }) => {
    wrapper = shallowMount(Header, {
      apolloProvider,
      propsData: {
        vulnerability: {
          ...defaultVulnerability,
          ...vulnerability,
        },
      },
      provide: {
        glFeatures: { deprecateVulnerabilitiesFeedback },
      },
    });
  };

  afterEach(() => {
    mockAxios.reset();
    createAlert.mockReset();
  });

  describe.each`
    action       | queryName                          | expected
    ${'dismiss'} | ${'vulnerabilityDismiss'}          | ${'dismissed'}
    ${'confirm'} | ${'vulnerabilityConfirm'}          | ${'confirmed'}
    ${'resolve'} | ${'vulnerabilityResolve'}          | ${'resolved'}
    ${'revert'}  | ${'vulnerabilityRevertToDetected'} | ${'detected'}
  `('state dropdown change', ({ action, queryName, expected }) => {
    describe('when API call is successful', () => {
      beforeEach(() => {
        const apolloProvider = createApolloProvider([
          vulnerabilityStateMutations[action],
          jest.fn().mockResolvedValue(getVulnerabilityStatusMutationResponse(queryName, expected)),
        ]);

        createWrapper({ apolloProvider });
      });

      it('shows the loading spinner but not the status badge', async () => {
        changeStatus(action);
        await nextTick();

        expect(findGlLoadingIcon().exists()).toBe(true);
        expect(findStatusBadge().exists()).toBe(false);
      });

      it(`emits the updated vulnerability properly - ${action}`, async () => {
        changeStatus(action);

        await waitForPromises();
        expect(wrapper.emitted('vulnerability-state-change')[0][0]).toMatchObject({
          state: expected,
        });
      });

      it(`emits an event when the state is changed - ${action}`, async () => {
        changeStatus(action);

        await waitForPromises();
        expect(wrapper.emitted()['vulnerability-state-change']).toHaveLength(1);
      });

      it('hides the loading spinner and shows the status badge', async () => {
        changeStatus(action);
        await waitForPromises();

        expect(findGlLoadingIcon().exists()).toBe(false);
        expect(findStatusBadge().exists()).toBe(true);
      });
    });

    describe('when API call is failed', () => {
      beforeEach(() => {
        const apolloProvider = createApolloProvider([
          vulnerabilityStateMutations[action],
          jest.fn().mockRejectedValue({
            data: {
              [queryName]: {
                errors: [{ message: 'Something went wrong' }],
                vulnerability: {},
              },
            },
          }),
        ]);

        createWrapper({ apolloProvider });
      });

      it('when the vulnerability state changes but the API call fails, an error message is displayed', async () => {
        changeStatus(action);

        await waitForPromises();
        expect(createAlert).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('split button', () => {
    it('renders the create merge request and issue button as a split button', () => {
      createWrapper({ vulnerability: getVulnerability({ shouldShowMergeRequestButton: true }) });
      expect(findSplitButton().exists()).toBe(true);
      const buttons = findSplitButton().props('buttons');
      expect(buttons).toHaveLength(2);
      expect(buttons[0].name).toBe('Resolve with merge request');
      expect(buttons[1].name).toBe('Download patch to resolve');
    });

    it('does not render the split button if there is only one action', () => {
      createWrapper({
        vulnerability: getVulnerability({
          shouldShowMergeRequestButton: true,
          shouldShowDownloadPatchButton: false,
        }),
      });
      expect(findSplitButton().exists()).toBe(false);
    });
  });

  describe('single action button', () => {
    it('does not display if there are no actions', () => {
      createWrapper({ vulnerability: getVulnerability({}) });
      expect(findGlButton().exists()).toBe(false);
    });

    describe.each([true, false])(
      'create merge request - deprecateVulnerabilitiesFeedback feature flag %s',
      (deprecateVulnerabilitiesFeedback) => {
        beforeEach(() => {
          createWrapper({
            deprecateVulnerabilitiesFeedback,
            vulnerability: {
              ...getVulnerability({
                shouldShowMergeRequestButton: true,
                shouldShowDownloadPatchButton: false,
              }),
            },
          });
        });

        it('only renders the create merge request button', () => {
          expect(findGlButton().exists()).toBe(true);
          expect(findGlButton().text()).toBe('Resolve with merge request');
        });

        it('emits createMergeRequest when create merge request button is clicked', async () => {
          const mergeRequestPath = '/group/project/merge_request/123';
          const spy = jest.spyOn(urlUtility, 'redirectTo');
          mockAxios.onPost(defaultVulnerability.createMrUrl).reply(HTTP_STATUS_OK, {
            merge_request_path: mergeRequestPath,
            merge_request_links: [{ merge_request_path: mergeRequestPath }],
          });
          findGlButton().vm.$emit('click');
          await waitForPromises();

          expect(spy).toHaveBeenCalledWith(mergeRequestPath);
          expect(mockAxios.history.post).toHaveLength(1);
          expect(JSON.parse(mockAxios.history.post[0].data)).toMatchObject({
            vulnerability_feedback: {
              feedback_type: FEEDBACK_TYPES.MERGE_REQUEST,
              category: defaultVulnerability.reportType,
              project_fingerprint: defaultVulnerability.projectFingerprint,
              finding_uuid: defaultVulnerability.uuid,
              vulnerability_data: {
                ...convertObjectPropsToSnakeCase(
                  getVulnerability({ shouldShowMergeRequestButton: true }),
                ),
                category: defaultVulnerability.reportType,
                state: 'resolved',
              },
            },
          });
        });

        it('shows an error message when merge request creation fails', () => {
          mockAxios
            .onPost(defaultVulnerability.create_mr_url)
            .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
          findGlButton().vm.$emit('click');
          return waitForPromises().then(() => {
            expect(mockAxios.history.post).toHaveLength(1);
            expect(createAlert).toHaveBeenCalledWith({
              message: 'There was an error creating the merge request. Please try again.',
            });
          });
        });
      },
    );

    describe('can download patch', () => {
      beforeEach(() => {
        createWrapper({
          vulnerability: {
            ...getVulnerability({ shouldShowMergeRequestButton: true }),
            createMrUrl: '',
          },
        });
      });

      it('only renders the download patch button', () => {
        expect(findGlButton().exists()).toBe(true);
        expect(findGlButton().text()).toBe('Download patch to resolve');
      });

      it('emits downloadPatch when download patch button is clicked', async () => {
        findGlButton().vm.$emit('click');
        await nextTick();
        expect(download).toHaveBeenCalledWith({ fileData: diff, fileName: `remediation.patch` });
      });
    });
  });

  describe('status description', () => {
    let vulnerability;
    let user;

    beforeEach(() => {
      user = createRandomUser();

      vulnerability = {
        ...defaultVulnerability,
        state: 'confirmed',
        confirmedById: user.id,
      };

      createWrapper({ vulnerability });
    });

    it('the status description is rendered and passed the correct data', () => {
      return waitForPromises().then(() => {
        expect(findStatusDescription().exists()).toBe(true);
        expect(findStatusDescription().props()).toEqual({
          vulnerability,
          user,
          isLoadingVulnerability: wrapper.vm.isLoadingVulnerability,
          isLoadingUser: wrapper.vm.isLoadingUser,
          isStatusBolded: false,
        });
      });
    });
  });

  describe('when the vulnerability is no longer detected on the default branch', () => {
    const branchName = 'main';

    beforeEach(() => {
      createWrapper({
        vulnerability: {
          resolvedOnDefaultBranch: true,
          projectDefaultBranch: branchName,
        },
      });
    });

    it('should show the resolution alert component', () => {
      const alert = findResolutionAlert();

      expect(alert.exists()).toBe(true);
    });

    it('should pass down the default branch name', () => {
      const alert = findResolutionAlert();

      expect(alert.props().defaultBranchName).toEqual(branchName);
    });

    it('the resolution alert component should not be shown if when the vulnerability is already resolved', async () => {
      wrapper.vm.vulnerability.state = 'resolved';
      await nextTick();
      const alert = findResolutionAlert();

      expect(alert.exists()).toBe(false);
    });
  });

  describe('vulnerability user watcher', () => {
    it.each(vulnerabilityStateEntries)(
      `loads the correct user for the vulnerability state "%s"`,
      (state) => {
        const user = createRandomUser();
        createWrapper({ vulnerability: { state, [`${state}ById`]: user.id } });

        return waitForPromises().then(() => {
          expect(mockAxios.history.get).toHaveLength(1);
          expect(findStatusDescription().props('user')).toEqual(user);
        });
      },
    );

    it('does not load a user if there is no user ID', () => {
      createWrapper({ vulnerability: { state: 'detected' } });

      return waitForPromises().then(() => {
        expect(mockAxios.history.get).toHaveLength(0);
        expect(findStatusDescription().props('user')).toBeUndefined();
      });
    });

    it('will show an error when the user cannot be loaded', () => {
      createWrapper({ vulnerability: { state: 'confirmed', confirmedById: 1 } });

      mockAxios.onGet().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      return waitForPromises().then(() => {
        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(mockAxios.history.get).toHaveLength(1);
      });
    });

    it('will set the isLoadingUser property correctly when the user is loading and finished loading', () => {
      const user = createRandomUser();
      createWrapper({ vulnerability: { state: 'confirmed', confirmedById: user.id } });

      expect(findStatusDescription().props('isLoadingUser')).toBe(true);

      return waitForPromises().then(() => {
        expect(mockAxios.history.get).toHaveLength(1);
        expect(findStatusDescription().props('isLoadingUser')).toBe(false);
      });
    });
  });
});
