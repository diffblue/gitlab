import DropLab from './droplab/drop_lab';
import ISetter from './droplab/plugins/input_setter';

// Todo: Remove this when fixing issue in input_setter plugin
const InputSetter = { ...ISetter };

class CommentTypeToggle {
  constructor(opts = {}) {
    this.dropdownTrigger = opts.dropdownTrigger;
    this.dropdownList = opts.dropdownList;
    this.noteTypeInput = opts.noteTypeInput;
    this.submitButton = opts.submitButton;
  }

  initDroplab() {
    this.droplab = new DropLab();

    const config = this.setConfig();

    this.droplab.init(this.dropdownTrigger, this.dropdownList, [InputSetter], config);
  }

  setConfig() {
    const config = {
      InputSetter: [
        {
          // when option is clicked, sets the `value` attribute on
          // `#note_type` to whatever the `data-value` attribute was
          // on the clicked option
          input: this.noteTypeInput,
          valueAttribute: 'data-value',
        },
        {
          // when option is clicked, sets the `value` attribute on
          // `.js-comment-type-dropdown .js-comment-submit-button` to
          // whatever the `data-value` attribute was on the clicked
          // option
          input: this.submitButton,
          valueAttribute: 'data-submit-text',
        },
      ],
    };

    return config;
  }
}

export default CommentTypeToggle;
