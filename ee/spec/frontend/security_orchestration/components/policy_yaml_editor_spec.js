import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import PolicyYamlEditor from 'ee/security_orchestration/components/policy_yaml_editor.vue';
import axios from '~/lib/utils/axios_utils';
import SourceEditor from '~/vue_shared/components/source_editor.vue';
import { EDITOR_READY_EVENT } from '~/editor/constants';

describe('PolicyYamlEditor component', () => {
  let wrapper;

  let editorInstanceDetail;
  let mockEditorInstance;
  let mockRegisterSecurityPolicySchema;
  let mockUse;
  let mock;

  const mockNamespacePath = 'test/path';
  const mockNamespaceType = 'testType';
  const mockPolicyType = 'testPolicyType';

  const findEditor = () => wrapper.findComponent(SourceEditor);

  const factory = ({ propsData } = {}) => {
    wrapper = shallowMount(PolicyYamlEditor, {
      propsData: {
        value: 'foo',
        policyType: mockPolicyType,
        ...propsData,
      },
      provide: {
        namespacePath: mockNamespacePath,
        namespaceType: mockNamespaceType,
      },
      stubs: {
        SourceEditor,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mockUse = jest.fn();
    mockRegisterSecurityPolicySchema = jest.fn();
    mockEditorInstance = {
      use: mockUse,
      registerSecurityPolicySchema: mockRegisterSecurityPolicySchema,
    };
    editorInstanceDetail = {
      detail: {
        instance: mockEditorInstance,
      },
    };
    factory();
  });

  afterEach(() => {
    mock.restore();
  });

  it('renders container element', () => {
    expect(findEditor().exists()).toBe(true);
  });

  it('initializes monaco editor with yaml language and provided value', () => {
    const editorComponent = findEditor();
    expect(editorComponent.props('value')).toBe('foo');
    const editor = editorComponent.vm.getEditor();
    expect(editor.getModel().getLanguageId()).toBe('yaml');
  });

  it("emits input event on editor's input", async () => {
    const editor = findEditor();
    editor.vm.$emit('input', 'foo');
    await nextTick();
    expect(wrapper.emitted().input).toEqual([['foo']]);
  });

  it('configures editor with syntax highlighting', () => {
    findEditor().vm.$emit(EDITOR_READY_EVENT, editorInstanceDetail);

    expect(mockUse).toHaveBeenCalledTimes(1);
    expect(mockRegisterSecurityPolicySchema).toHaveBeenCalledTimes(1);
    expect(mockRegisterSecurityPolicySchema).toHaveBeenCalledWith({
      namespacePath: mockNamespacePath,
      namespaceType: mockNamespaceType,
      policyType: mockPolicyType,
    });
  });
});
