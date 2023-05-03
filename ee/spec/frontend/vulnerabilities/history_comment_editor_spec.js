import { GlFormTextarea } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import HistoryCommentEditor from 'ee/vulnerabilities/components/history_comment_editor.vue';

describe('History Comment Editor', () => {
  let wrapper;

  const createWrapper = (props) => {
    wrapper = shallowMount(HistoryCommentEditor, {
      propsData: { isSaving: false, ...props },
    });
  };

  const textarea = () => wrapper.findComponent(GlFormTextarea);
  const saveButton = () => wrapper.findComponent({ ref: 'saveButton' });
  const cancelButton = () => wrapper.findComponent({ ref: 'cancelButton' });

  it('shows the placeholder text when there is no comment', () => {
    createWrapper();
    expect(textarea().props('value')).toBe('');
  });

  it('shows the comment when one is passed in', () => {
    const initialComment = 'some comment';
    createWrapper({ initialComment });
    expect(textarea().props('value')).toBe(initialComment);
  });

  it('trims the comment when there are extra spaces', () => {
    const initialComment = '    some comment    ';
    createWrapper({ initialComment });
    expect(textarea().props('value')).toBe(initialComment.trim());
  });

  it('emits the save event with the new comment when the save button is clicked', () => {
    createWrapper();
    const comment = 'new comment';
    textarea().vm.$emit('input', comment);
    saveButton().vm.$emit('click');

    expect(wrapper.emitted().onSave).toHaveLength(1);
    expect(wrapper.emitted().onSave[0][0]).toBe(comment);
  });

  it('sanitizes a new comment to protect against an XSS attack', () => {
    createWrapper();
    const comment = '"><img src=x onerror=alert(document.domain)>';
    const sanitizedComment = '"&gt;<img src="x">';
    textarea().vm.$emit('input', comment);
    saveButton().vm.$emit('click');

    expect(wrapper.emitted().onSave).toHaveLength(1);
    expect(wrapper.emitted().onSave[0][0]).toBe(sanitizedComment);
  });

  it('sanitizes a new comment to protect against an XSS attack using an iframe', () => {
    createWrapper();
    const comment = `"><iframe src='hxxps://nefarious.com'>'`;
    const sanitizedComment = `"&gt;`;
    textarea().vm.$emit('input', comment);
    saveButton().vm.$emit('click');

    expect(wrapper.emitted().onSave).toHaveLength(1);
    expect(wrapper.emitted().onSave[0][0]).toBe(sanitizedComment);
  });

  it('emits the cancel event when the cancel button is clicked', () => {
    createWrapper();
    cancelButton().vm.$emit('click');

    expect(wrapper.emitted().onCancel).toHaveLength(1);
  });

  it('disables the save button when there is no text or only whitespace in the textarea', async () => {
    createWrapper({ initialComment: 'some comment' });
    textarea().vm.$emit('input', '    ');
    await nextTick();

    expect(saveButton().props('disabled')).toBe(true);
  });

  it('disables all elements when the comment is being saved', () => {
    createWrapper({ isSaving: true });

    expect(textarea().attributes('disabled')).toBeDefined();
    expect(saveButton().props('loading')).toBe(true);
    expect(cancelButton().props('disabled')).toBe(true);
  });
});
