import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import TestCaseCreateRoot from 'ee/test_case_create/components/test_case_create_root.vue';
import createTestCase from 'ee/test_case_create/queries/create_test_case.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { createAlert } from '~/alert';
import IssuableCreate from '~/vue_shared/issuable/create/components/issuable_create_root.vue';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

Vue.use(VueApollo);

const mockProvide = {
  projectFullPath: 'gitlab-org/gitlab-test',
  projectTestCasesPath: '/gitlab-org/gitlab-test/-/quality/test_cases',
  descriptionPreviewPath: '/gitlab-org/gitlab-test/preview_markdown',
  descriptionHelpPath: '/help/user/markdown',
  labelsFetchPath: '/gitlab-org/gitlab-test/-/labels.json',
  labelsManagePath: '/gitlab-org/gitlab-shell/-/labels',
};

const mutationResponseSuccess = {
  data: {
    createTestCase: {
      clientMutationId: '',
      errors: [],
    },
  },
};

const titleError = 'Title is too long';

const mutationResponseError = {
  data: {
    createTestCase: {
      clientMutationId: '',
      errors: [titleError],
    },
  },
};

const mutationSuccessHandler = jest.fn().mockResolvedValue(mutationResponseSuccess);

describe('TestCaseCreateRoot', () => {
  let wrapper;

  const findSubmitButton = () => wrapper.findByTestId('submit-test-case');
  const findCancelButton = () => wrapper.findByTestId('cancel-test-case');

  const createComponent = ({ title = '', handler = mutationSuccessHandler } = {}) => {
    wrapper = shallowMountExtended(TestCaseCreateRoot, {
      provide: mockProvide,
      apolloProvider: createMockApollo([[createTestCase, handler]]),
      stubs: {
        IssuableCreate,
        IssuableForm: {
          template: `
            <div>
              <slot
                name="actions"
                issuable-title="${title}"
                issuable-description="Test description"
                :selected-labels="[]"
              ></slot>
            </div>
          `,
        },
      },
    });
  };

  it('renders disabled `Submit test case` button if no title is entered', () => {
    createComponent();

    expect(findSubmitButton().props('disabled')).toBe(true);
  });

  it('renders enabled `Submit test case` button if title is entered', () => {
    createComponent({ title: 'Test title' });

    expect(findSubmitButton().props('disabled')).toBe(false);
  });

  describe('when creating new case', () => {
    it('calls mutation on submit button click', () => {
      createComponent({ title: 'Test title' });
      findSubmitButton().vm.$emit('click');

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        createTestCaseInput: {
          description: 'Test description',
          labelIds: [],
          projectPath: 'gitlab-org/gitlab-test',
          title: 'Test title',
        },
      });
    });

    it('shows loading state on submit button', async () => {
      createComponent({ title: 'Test title' });
      findSubmitButton().vm.$emit('click');
      await nextTick();

      expect(findSubmitButton().props('loading')).toBe(true);
    });

    it('disables cancel button', async () => {
      createComponent({ title: 'Test title' });
      findSubmitButton().vm.$emit('click');
      await nextTick();

      expect(findCancelButton().props('disabled')).toBe(true);
    });

    it('redirects after successful mutation', async () => {
      createComponent({ title: 'Test title' });
      findSubmitButton().vm.$emit('click');

      await waitForPromises();

      expect(redirectTo).toHaveBeenCalledWith(mockProvide.projectTestCasesPath); // eslint-disable-line import/no-deprecated
    });
  });

  it('shows an error when mutation has unrecoverable error', async () => {
    const mockError = new Error();
    createComponent({
      title: 'Test title',
      handler: jest.fn().mockRejectedValue(mockError),
    });
    findSubmitButton().vm.$emit('click');
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      captureError: true,
      error: mockError,
      message: 'Something went wrong while creating a test case.',
    });
  });

  it('shows a warning  when mutation has recoverable error', async () => {
    createComponent({
      title: 'Test title',
      handler: jest.fn().mockResolvedValue(mutationResponseError),
    });
    findSubmitButton().vm.$emit('click');
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      captureError: true,
      error: titleError,
      message: titleError,
    });
  });
});
