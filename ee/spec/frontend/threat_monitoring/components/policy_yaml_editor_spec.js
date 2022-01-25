import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import PolicyYamlEditor from 'ee/threat_monitoring/components/policy_yaml_editor.vue';
import SourceEditor from '~/vue_shared/components/source_editor.vue';

describe('PolicyYamlEditor component', () => {
  let wrapper;

  const findEditor = () => wrapper.findComponent(SourceEditor);

  const factory = ({ propsData } = {}) => {
    wrapper = shallowMount(PolicyYamlEditor, {
      propsData: {
        value: 'foo',
        ...propsData,
      },
      stubs: {
        SourceEditor,
      },
    });
  };

  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders container element', () => {
    expect(findEditor().exists()).toBe(true);
  });

  it('initializes monaco editor with yaml language and provided value', () => {
    const editorComponent = findEditor();
    expect(editorComponent.props('value')).toBe('foo');
    const editor = editorComponent.vm.getEditor();
    expect(editor.getModel().getModeId()).toBe('yaml');
  });

  it("emits input event on editor's input", async () => {
    const editor = findEditor();
    editor.vm.$emit('input');
    await nextTick();
    expect(wrapper.emitted().input).toBeTruthy();
  });
});
