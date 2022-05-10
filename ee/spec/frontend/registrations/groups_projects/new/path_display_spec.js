import {
  displayGroupPath,
  displayProjectPath,
} from 'ee/registrations/groups_projects/new/path_display';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { useMockMutationObserver } from 'helpers/mock_dom_observer';

const findSource = () => document.querySelector('.source');
const displayValue = () => document.querySelector('.display').textContent;

describe('displayGroupPath', () => {
  const { trigger: triggerMutate } = useMockMutationObserver();

  beforeEach(() => {
    setHTMLFixture("<input type='text' class='source'><div class='display'>original value<div>");
    displayGroupPath('.source', '.display');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  const inputSource = (value) => {
    const source = findSource();
    source.value = value;
    triggerMutate(source, {
      entry: { attributeName: 'value' },
      options: { attributes: true },
    });
  };

  it('coppies values from the source to the display', () => {
    inputSource('peanut-butter-jelly-time');
    expect(displayValue()).toBe('peanut-butter-jelly-time');
  });
});

describe('displayProjectPath', () => {
  beforeEach(() => {
    setHTMLFixture("<input type='text' class='source'><div class='display'>original value<div>");
    displayProjectPath('.source', '.display');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  const inputSource = (value) => {
    const source = findSource();
    source.value = value;
    source.dispatchEvent(new Event('input'));
  };

  it('displays the default display value when source is empty', () => {
    expect(displayValue()).toBe('original value');
    inputSource('its a peanut butter jelly');
    expect(displayValue()).not.toBe('original value');
    inputSource('');
    expect(displayValue()).toBe('original value');
  });

  it('sluggifies values from the source to the display', () => {
    inputSource('peanut butter jelly time');
    expect(displayValue()).toBe('peanut-butter-jelly-time');
  });
});
