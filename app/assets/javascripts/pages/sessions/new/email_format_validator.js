import { __ } from '~/locale';
import InputValidator from '~/validators/input_validator';

const emailRegexPattern = /[^@\s]+@[^@\s]+\.[^@\s]+/;

export default class EmailFormatValidator extends InputValidator {
  constructor(opts = {}) {
    super();

    const container = opts.container || '';
    this.elements = document.querySelectorAll(`${container} .js-validate-email`);

    this.elements.forEach((element) =>
      element.addEventListener('input', this.eventHandler.bind(this)),
    );
  }

  eventHandler(event) {
    this.inputDomElement = event.target;
    this.inputErrorMessage = this.inputDomElement.nextSibling;

    const { value } = this.inputDomElement;

    this.errorMessage = __('Please provide a valid email address.');

    this.validatePattern(value);
    this.setValidationStateAndMessage();
  }

  validatePattern(value) {
    this.invalidInput = !new RegExp(emailRegexPattern).test(value);
  }
}
