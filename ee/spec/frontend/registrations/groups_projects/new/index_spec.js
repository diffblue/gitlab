import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import mountComponents from 'ee/registrations/groups_projects/new';
import * as showTooltip from 'ee/registrations/groups_projects/new/show_tooltip';

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

describe('mobileTooltipOpts', () => {
  let showTooltipSpy;

  beforeEach(() => {
    showTooltipSpy = jest.spyOn(showTooltip, 'default');
  });

  it('when xs breakpoint size, passes placement options', () => {
    jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('xs');
    setup();
    expect(showTooltipSpy).toHaveBeenCalledWith(expect.any(String), { placement: 'bottom' });
    resetHTMLFixture();
  });

  it('when not xs breakpoint size, passes emptyt tooltip options', () => {
    jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('lg');
    setup();
    expect(showTooltipSpy).toHaveBeenCalledWith(expect.any(String), {});
    resetHTMLFixture();
  });
});
