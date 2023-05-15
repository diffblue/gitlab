import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ClipboardJS from 'clipboard';
import { merge } from 'lodash';
import ConfigurationSnippetModal from 'ee/security_configuration/components/configuration_snippet_modal.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import SourceEditor from '~/vue_shared/components/source_editor.vue';

jest.mock('clipboard', () =>
  jest.fn().mockImplementation(() => ({
    on: jest.fn().mockImplementation((_event, cb) => cb()),
  })),
);

jest.mock('~/lib/utils/url_utility', () => {
  const urlUtility = jest.requireActual('~/lib/utils/url_utility');

  return {
    ...urlUtility,
    getBaseURL: jest.fn().mockReturnValue('http://gitlab.local/'),
    redirectTo: jest.fn(),
  };
});

const gitlabCiYamlEditPath = '/ci/editor';
const configurationYaml = 'YAML';
const redirectParam = 'foo';

describe('EE - SecurityConfigurationSnippetModal', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const helpText = () => wrapper.findByTestId('configuration-modal-help-text');
  const findEditor = () => wrapper.findComponent(SourceEditor);

  const createWrapper = (options) => {
    wrapper = extendedWrapper(
      shallowMount(
        ConfigurationSnippetModal,
        merge(
          {
            propsData: {
              ciYamlEditUrl: gitlabCiYamlEditPath,
              yaml: configurationYaml,
              redirectParam,
              scanType: 'API Fuzzing',
            },
            attrs: {
              static: true,
              visible: true,
            },
            stubs: {
              GlSprintf,
              SourceEditor,
            },
          },
          options,
        ),
      ),
    );
  };

  beforeEach(() => {
    createWrapper();
  });

  it('renders the YAML snippet', () => {
    expect(findEditor().exists()).toBe(true);
  });

  it('initializes editor with the provided configuration', () => {
    const editorComponent = findEditor();
    expect(editorComponent.vm.getEditor().getValue()).toBe(configurationYaml);
  });

  it('renders help text correctly', () => {
    expect(helpText().exists()).toBe(true);
    expect(helpText().text()).not.toBe('');
    expect(helpText().html()).toContain(gitlabCiYamlEditPath);
  });

  it('on primary event, text is copied to the clipbard and user is redirected to CI editor', () => {
    findModal().vm.$emit('primary');

    expect(ClipboardJS).toHaveBeenCalledWith('#copy-yaml-snippet-and-edit-button', {
      text: expect.any(Function),
    });
    // eslint-disable-next-line import/no-deprecated
    expect(redirectTo).toHaveBeenCalledWith(
      `http://gitlab.local${gitlabCiYamlEditPath}?code_snippet_copied_from=${redirectParam}`,
    );
  });

  it('on secondary event, text is copied to the clipbard', () => {
    findModal().vm.$emit('secondary');

    expect(ClipboardJS).toHaveBeenCalledWith('#copy-yaml-snippet-button', {
      text: expect.any(Function),
    });
  });
});
