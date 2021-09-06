import { slugify, convertUnicodeToAscii } from '~/lib/utils/text_utility';

class DisplayInputValue {
  constructor(sourceElementSelector, targetElementSelector, transformer) {
    this.sourceElement = document.querySelector(sourceElementSelector);
    this.targetElement = document.querySelector(targetElementSelector);
    this.originalTargetValue = this.targetElement?.textContent;
    this.transformer = transformer;
    this.updateHandler = this.update.bind(this);
  }

  update() {
    let { value } = this.sourceElement;
    if (value.length === 0) {
      value = this.originalTargetValue;
    } else if (this.transformer) {
      value = this.transformer(value);
    }

    this.targetElement.textContent = value;
  }

  listen(callback) {
    if (!this.sourceElement || !this.targetElement) return null;

    this.updateHandler();
    return callback(this.sourceElement, this.updateHandler);
  }
}

export const displayGroupPath = (sourceSelector, targetSelector) => {
  const display = new DisplayInputValue(sourceSelector, targetSelector);

  if (!display) return null;

  const callback = (sourceElement, updateHandler) => {
    const observer = new MutationObserver((mutationList) => {
      mutationList.forEach((mutation) => {
        if (mutation.attributeName === 'value') {
          updateHandler();
        }
      });
    });

    observer.observe(sourceElement, { attributes: true });
  };

  return display.listen(callback);
};

export const displayProjectPath = (sourceSelector, displaySelector) => {
  const transformer = (value) => slugify(convertUnicodeToAscii(value));
  const display = new DisplayInputValue(sourceSelector, displaySelector, transformer);

  if (!display) return null;

  const callback = (sourceElement, updateHandler) => {
    sourceElement.addEventListener('input', updateHandler);
  };

  return display.listen(callback);
};
