import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import mountComponents from 'ee/registrations/groups/new';

const setup = () => {
  const fixture = `
    <div class="js-import-project-buttons">
      <a href="/import/github">github</a>
    </div>

    <div class="js-import-project-form">
      <input type="hidden" class="js-import-url" />
      <input type="submit" />
    </form>
  `;
  setHTMLFixture(fixture);
  mountComponents();
};

describe('importButtonsSubmit', () => {
  beforeEach(() => {
    setup();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  const findSubmit = () => document.querySelector('.js-import-project-form input[type="submit"]');
  const findImportUrlValue = () => document.querySelector('.js-import-url').value;
  const findImportGithubButton = () => document.querySelector('.js-import-project-buttons a');

  it('sets the import-url field with the value of the href and clicks submit', () => {
    const submitSpy = jest.spyOn(findSubmit(), 'click');
    findImportGithubButton().click();
    expect(findImportUrlValue()).toBe('/import/github');
    expect(submitSpy).toHaveBeenCalled();
  });
});
