import { GlAlert, GlFormGroup, GlModal, GlSkeletonLoader } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import { createLocalVue, mount, shallowMount, createWrapper } from '@vue/test-utils';
import merge from 'lodash/merge';
import VueApollo from 'vue-apollo';
import DastSiteValidationModal from 'ee/security_configuration/dast_site_validation/components/dast_site_validation_modal.vue';
import dastSiteTokenCreateMutation from 'ee/security_configuration/dast_site_validation/graphql/dast_site_token_create.mutation.graphql';
import dastSiteValidationCreateMutation from 'ee/security_configuration/dast_site_validation/graphql/dast_site_validation_create.mutation.graphql';
import createApolloProvider from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import download from '~/lib/utils/downloader';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import * as responses from '../mock_data/apollo_mock';

jest.mock('~/lib/utils/downloader');

const localVue = createLocalVue();
localVue.use(VueApollo);

const fullPath = 'group/project';
const targetUrl = 'https://example.com/';
const tokenId = '1';
const token = 'validation-token-123';

const validationMethods = ['text file', 'header'];

const defaultProps = {
  fullPath,
  targetUrl,
};

const defaultRequestHandlers = {
  dastSiteTokenCreate: jest
    .fn()
    .mockResolvedValue(responses.dastSiteTokenCreate({ id: tokenId, token })),
  dastSiteValidationCreate: jest.fn().mockResolvedValue(responses.dastSiteValidationCreate()),
};

describe('DastSiteValidationModal', () => {
  let wrapper;
  let requestHandlers;

  const pendingHandler = jest.fn(() => new Promise(() => {}));

  const componentFactory = (mountFn = shallowMount) => ({
    mountOptions = {},
    handlers = {},
  } = {}) => {
    requestHandlers = { ...defaultRequestHandlers, ...handlers };
    wrapper = mountFn(
      DastSiteValidationModal,
      merge(
        {},
        {
          propsData: defaultProps,
          attrs: {
            static: true,
            visible: true,
          },
        },
        mountOptions,
        {
          localVue,
          apolloProvider: createApolloProvider([
            [dastSiteTokenCreateMutation, requestHandlers.dastSiteTokenCreate],
            [dastSiteValidationCreateMutation, requestHandlers.dastSiteValidationCreate],
          ]),
        },
      ),
    );
  };
  const createComponent = componentFactory();
  const createFullComponent = componentFactory(mount);

  const withinComponent = () => within(wrapper.find(GlModal).element);
  const findByTestId = (id) => wrapper.find(`[data-testid="${id}"`);
  const findDownloadButton = () => findByTestId('download-dast-text-file-validation-button');
  const findValidationPathPrefix = () => findByTestId('dast-site-validation-path-prefix');
  const findValidationPathInput = () => findByTestId('dast-site-validation-path-input');
  const findValidateButton = () => findByTestId('validate-dast-site-button');
  const findRadioInputForValidationMethod = (validationMethod) =>
    withinComponent().queryByRole('radio', {
      name: new RegExp(`${validationMethod} validation`, 'i'),
    });
  const enableValidationMethod = (validationMethod) =>
    createWrapper(findRadioInputForValidationMethod(validationMethod)).trigger('click');

  afterEach(() => {
    wrapper.destroy();
  });

  it("calls GlModal's show method when own show method is called", () => {
    const showMock = jest.fn();
    createComponent({
      mountOptions: {
        stubs: {
          GlModal: {
            render: () => {},
            methods: {
              show: showMock,
            },
          },
        },
      },
    });
    wrapper.vm.show();

    expect(showMock).toHaveBeenCalled();
  });

  describe('rendering', () => {
    describe('loading', () => {
      beforeEach(() => {
        createFullComponent({
          handlers: {
            dastSiteTokenCreate: pendingHandler,
          },
        });
      });

      it('renders a skeleton loader, no alert and no form group while token is being created', () => {
        expect(wrapper.find(GlSkeletonLoader).exists()).toBe(true);
        expect(wrapper.find(GlAlert).exists()).toBe(false);
        expect(wrapper.find(GlFormGroup).exists()).toBe(false);
      });
    });

    describe('error', () => {
      beforeEach(async () => {
        createFullComponent({
          handlers: {
            dastSiteTokenCreate: jest.fn().mockRejectedValue(new Error('GraphQL Network Error')),
          },
        });
        await waitForPromises();
      });

      it('renders an alert and no skeleton loader or form group if token could not be created', () => {
        expect(wrapper.find(GlAlert).exists()).toBe(true);
        expect(wrapper.find(GlSkeletonLoader).exists()).toBe(false);
        expect(wrapper.find(GlFormGroup).exists()).toBe(false);
      });
    });

    describe('loaded', () => {
      beforeEach(async () => {
        createFullComponent();
        await waitForPromises();
      });

      it('renders form groups, no alert and no skeleton loader', () => {
        expect(wrapper.find(GlFormGroup).exists()).toBe(true);
        expect(wrapper.find(GlAlert).exists()).toBe(false);
        expect(wrapper.find(GlSkeletonLoader).exists()).toBe(false);
      });

      it('renders a download button containing the token', () => {
        const downloadButton = withinComponent().getByRole('button', {
          name: 'Download validation text file',
        });
        expect(downloadButton).not.toBeNull();
      });

      it.each(validationMethods)(
        'renders a radio input for "%s" validation',
        (validationMethod) => {
          expect(findRadioInputForValidationMethod(validationMethod)).not.toBe(null);
        },
      );

      it('renders an input group with the target URL prepended', () => {
        const inputGroup = withinComponent().getByRole('group', {
          name: 'Step 3 - Confirm text file location and validate',
        });
        expect(inputGroup).not.toBeNull();
        expect(inputGroup.textContent).toContain(targetUrl);
      });
    });
  });

  it('triggers the dastSiteTokenCreate GraphQL mutation', () => {
    createComponent();

    expect(requestHandlers.dastSiteTokenCreate).toHaveBeenCalledWith({
      fullPath,
      targetUrl,
    });
  });

  describe('validation methods', () => {
    describe.each(validationMethods)('common behaviour', (validationMethod) => {
      const expectedFileName = `GitLab-DAST-Site-Validation-${token}.txt`;

      describe.each`
        targetUrl                               | expectedPrefix                 | expectedPath        | expectedTextFilePath
        ${'https://example.com'}                | ${'https://example.com/'}      | ${''}               | ${`${expectedFileName}`}
        ${'https://example.com/'}               | ${'https://example.com/'}      | ${''}               | ${`${expectedFileName}`}
        ${'https://example.com/foo/bar'}        | ${'https://example.com/'}      | ${'foo/bar'}        | ${`foo/${expectedFileName}`}
        ${'https://example.com/foo/bar/'}       | ${'https://example.com/'}      | ${'foo/bar/'}       | ${`foo/bar/${expectedFileName}`}
        ${'https://sub.example.com/foo/bar'}    | ${'https://sub.example.com/'}  | ${'foo/bar'}        | ${`foo/${expectedFileName}`}
        ${'https://example.com/foo/index.html'} | ${'https://example.com/'}      | ${'foo/index.html'} | ${`foo/${expectedFileName}`}
        ${'https://example.com/foo/?bar="baz"'} | ${'https://example.com/'}      | ${'foo/'}           | ${`foo/${expectedFileName}`}
        ${'https://example.com:3000'}           | ${'https://example.com:3000/'} | ${''}               | ${`${expectedFileName}`}
        ${''}                                   | ${''}                          | ${''}               | ${`${expectedFileName}`}
      `(
        `validation path input when validationMethod is "${validationMethod}" and target URL is "$targetUrl"`,
        ({ targetUrl: url, expectedPrefix, expectedPath, expectedTextFilePath }) => {
          beforeEach(async () => {
            createFullComponent({
              mountOptions: {
                propsData: {
                  targetUrl: url,
                },
              },
            });
            await waitForPromises();

            enableValidationMethod(validationMethod);
          });

          const expectedValue =
            validationMethod === 'text file' ? expectedTextFilePath : expectedPath;

          it(`prefix is set to "${expectedPrefix}"`, () => {
            expect(findValidationPathPrefix().text()).toBe(expectedPrefix);
          });

          it(`input value defaults to "${expectedValue}"`, () => {
            expect(findValidationPathInput().element.value).toBe(expectedValue);
          });
        },
      );

      it("input value isn't automatically updated if it has been changed manually", async () => {
        createFullComponent();
        await waitForPromises();
        const customValidationPath = 'custom/validation/path.txt';
        findValidationPathInput().setValue(customValidationPath);
        await wrapper.setProps({
          token: 'a-completely-new-token',
        });

        expect(findValidationPathInput().element.value).toBe(customValidationPath);
      });
    });

    describe('text file validation', () => {
      it('clicking on the download button triggers a download of a text file containing the token', async () => {
        createComponent();
        await waitForPromises();
        findDownloadButton().vm.$emit('click');

        expect(download).toHaveBeenCalledWith({
          fileName: `GitLab-DAST-Site-Validation-${token}.txt`,
          fileData: btoa(token),
        });
      });
    });

    describe('header validation', () => {
      beforeEach(async () => {
        createFullComponent();

        await waitForPromises();

        enableValidationMethod('header');
      });

      it.each([
        /step 2 - add following http header to your site/i,
        /step 3 - confirm header location and validate/i,
      ])('shows the correct descriptions', (descriptionText) => {
        expect(withinComponent().getByText(descriptionText)).not.toBe(null);
      });

      it('shows a code block containing the http-header key with the given token', () => {
        expect(
          withinComponent().getByText(`Gitlab-On-Demand-DAST: ${token}`, {
            selector: 'code',
          }),
        ).not.toBe(null);
      });

      it('shows a button that copies the http-header to the clipboard', () => {
        const clipboardButton = wrapper.find(ModalCopyButton);

        expect(clipboardButton.exists()).toBe(true);
        expect(clipboardButton.props()).toMatchObject({
          text: `Gitlab-On-Demand-DAST: ${token}`,
          title: 'Copy HTTP header to clipboard',
        });
      });
    });
  });

  describe.each(validationMethods)('"%s" validation submission', (validationMethod) => {
    beforeEach(async () => {
      createFullComponent();
      await waitForPromises();
    });

    describe('passed', () => {
      beforeEach(() => {
        enableValidationMethod(validationMethod);
      });

      it('triggers the dastSiteValidationCreate GraphQL mutation', () => {
        findValidateButton().trigger('click');

        expect(requestHandlers.dastSiteValidationCreate).toHaveBeenCalledWith({
          fullPath,
          dastSiteTokenId: tokenId,
          validationPath: wrapper.vm.validationPath,
          validationStrategy: wrapper.vm.validationMethod,
        });
      });
    });
  });
});
