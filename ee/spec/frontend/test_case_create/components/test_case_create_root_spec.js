import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import TestCaseCreateRoot from 'ee/test_case_create/components/test_case_create_root.vue';
import createTestCase from 'ee/test_case_create/queries/create_test_case.mutation.graphql';

import createFlash from '~/flash';
import IssuableCreate from '~/vue_shared/issuable/create/components/issuable_create_root.vue';
import IssuableForm from '~/vue_shared/issuable/create/components/issuable_form.vue';
import { redirectTo } from '~/lib/utils/url_utility';

jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility');

const mockProvide = {
  projectFullPath: 'gitlab-org/gitlab-test',
  projectTestCasesPath: '/gitlab-org/gitlab-test/-/quality/test_cases',
  descriptionPreviewPath: '/gitlab-org/gitlab-test/preview_markdown',
  descriptionHelpPath: '/help/user/markdown',
  labelsFetchPath: '/gitlab-org/gitlab-test/-/labels.json',
  labelsManagePath: '/gitlab-org/gitlab-shell/-/labels',
};

const createComponent = () =>
  shallowMount(TestCaseCreateRoot, {
    provide: mockProvide,
    mocks: {
      $apollo: {
        mutate: jest.fn(),
      },
    },
    stubs: {
      IssuableCreate,
      IssuableForm,
    },
  });

describe('TestCaseCreateRoot', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('methods', () => {
    describe('handleTestCaseSubmitClick', () => {
      const issuableTitle = 'Sample title';
      const issuableDescription = 'Sample _description_.';
      const selectedLabels = [
        {
          id: 1,
          set: true,
          color: '#BADA55',
          text_color: '#FFFFFF',
          title: 'Bug',
        },
      ];
      const mockCreateMutationResult = {
        data: {
          createTestCase: {
            errors: [],
          },
        },
      };

      it('sets `createTestCaseRequestActive` prop to true', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockCreateMutationResult);

        wrapper.vm.handleTestCaseSubmitClick({
          issuableTitle,
          issuableDescription,
          selectedLabels,
        });

        expect(wrapper.vm.createTestCaseRequestActive).toBe(true);
      });

      it('calls `$apollo.mutate` with `createTestCase` mutation and input variables containing projectPath, title, description and labelIds', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockCreateMutationResult);

        wrapper.vm.handleTestCaseSubmitClick({
          issuableTitle,
          issuableDescription,
          selectedLabels,
        });

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: createTestCase,
            variables: {
              createTestCaseInput: {
                projectPath: 'gitlab-org/gitlab-test',
                title: issuableTitle,
                description: issuableDescription,
                labelIds: selectedLabels.map((label) => label.id),
              },
            },
          }),
        );
      });

      it('calls `redirectTo` with projectTestCasesPath when mutation is successful', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockCreateMutationResult);

        return wrapper.vm
          .handleTestCaseSubmitClick({
            issuableTitle,
            issuableDescription,
            selectedLabels,
          })
          .then(() => {
            expect(redirectTo).toHaveBeenCalledWith(mockProvide.projectTestCasesPath);
          })
          .finally(() => {
            expect(wrapper.vm.createTestCaseRequestActive).toBe(false);
          });
      });

      it('calls `createFlash` with message and error captured when mutation fails', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue({});

        return wrapper.vm
          .handleTestCaseSubmitClick({
            issuableTitle,
            issuableDescription,
            selectedLabels,
          })
          .then(() => {
            expect(createFlash).toHaveBeenCalledWith({
              message: 'Something went wrong while creating a test case.',
              captureError: true,
              error: expect.any(Object),
            });
          })
          .finally(() => {
            expect(wrapper.vm.createTestCaseRequestActive).toBe(false);
          });
      });
    });
  });

  describe('template', () => {
    it('renders issuable-create as a root component', () => {
      const {
        descriptionPreviewPath,
        descriptionHelpPath,
        labelsFetchPath,
        labelsManagePath,
      } = mockProvide;

      expect(wrapper.findComponent(IssuableCreate).exists()).toBe(true);
      expect(wrapper.findComponent(IssuableCreate).props()).toMatchObject({
        descriptionPreviewPath,
        descriptionHelpPath,
        labelsFetchPath,
        labelsManagePath,
      });
    });

    it('renders page title', () => {
      expect(wrapper.find('h3').text()).toBe('New Test Case');
    });

    it('renders page actions', () => {
      const submitEl = wrapper.find('[data-testid="submit-test-case"]');
      const cancelEl = wrapper.find('[data-testid="cancel-test-case"]');

      expect(submitEl.text()).toBe('Submit test case');
      expect(submitEl.props()).toMatchObject({
        loading: false,
        disabled: true,
      });
      expect(cancelEl.text()).toBe('Cancel');
      expect(cancelEl.props('disabled')).toBe(false);
      expect(cancelEl.attributes('href')).toBe(mockProvide.projectTestCasesPath);
    });

    it('submit button shows loading animation when `createTestCaseRequestActive` is true', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        createTestCaseRequestActive: true,
      });

      await nextTick();

      expect(wrapper.find('[data-testid="submit-test-case"]').props('loading')).toBe(true);
    });

    it('cancel button is disabled when `createTestCaseRequestActive` is true', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        createTestCaseRequestActive: true,
      });

      await nextTick();

      expect(wrapper.find('[data-testid="cancel-test-case"]').props('disabled')).toBe(true);
    });

    describe('events', () => {
      it('submit button click calls `handleTestCaseSubmitClick` method', () => {
        jest.spyOn(wrapper.vm, 'handleTestCaseSubmitClick').mockImplementation(jest.fn);

        const submitButton = wrapper.find('[data-testid="submit-test-case"]');

        submitButton.vm.$emit('click');

        expect(wrapper.vm.handleTestCaseSubmitClick).toHaveBeenCalledWith({
          issuableTitle: '',
          issuableDescription: '',
          selectedLabels: [],
        });
      });
    });
  });
});
