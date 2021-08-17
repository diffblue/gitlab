# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::IterationReferenceFilter do
  include FilterSpecHelper

  let(:parent_group) { create(:group, :public) }
  let(:group) { create(:group, :public, parent: parent_group) }
  let(:project) { create(:project, :public, group: group) }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  shared_examples 'reference parsing' do
    %w(pre code a style).each do |elem|
      it "ignores valid references contained inside '#{elem}' element" do
        exp = act = "<#{elem}>iteration #{reference}</#{elem}>"
        expect(reference_filter(act).to_html).to eq exp
      end
    end

    it 'includes default classes' do
      doc = reference_filter("Iteration #{reference}")

      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-iteration has-tooltip'
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Iteration #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-iteration attribute' do
      doc = reference_filter("See #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-iteration')
      expect(link.attr('data-iteration')).to eq iteration.id.to_s
    end

    it 'supports an :only_path context' do
      doc = reference_filter("Iteration #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r(https?://)
      expect(link).to eq urls.iteration_path(iteration)
    end
  end

  shared_examples 'Integer-based references' do
    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.iteration_url(iteration)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Iteration (#{reference}.)")

      expect(doc.to_html).to match(%r(\(<a.+>#{iteration.reference_link_text}</a>\.\)))
    end

    it 'ignores invalid iteration IIDs' do
      exp = act = "Iteration #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  shared_examples 'String-based single-word references' do
    let(:reference) { "#{Iteration.reference_prefix}#{iteration.name}" }

    before do
      iteration.update!(name: 'gfm')
    end

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.iteration_url(iteration)
      expect(doc.text).to eq "See #{iteration.reference_link_text}"
    end

    it 'links with adjacent text' do
      doc = reference_filter("Iteration (#{reference}.)")

      expect(doc.to_html).to match(%r(\(<a.+>#{iteration.reference_link_text}</a>\.\)))
    end

    it 'links with adjacent html tags' do
      doc = reference_filter("Iteration <p>#{reference}</p>.")
      expect(doc.to_html).to match(%r(<p><a.+>#{iteration.reference_link_text}</a></p>))
    end

    it 'ignores invalid iteration names' do
      exp = act = "Iteration #{Iteration.reference_prefix}#{iteration.name.reverse}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  shared_examples 'String-based multi-word references in quotes' do
    let(:reference) { iteration.to_reference(format: :name) }

    before do
      iteration.update!(name: 'gfm references')
    end

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.iteration_url(iteration)
      expect(doc.text).to eq "See #{iteration.reference_link_text}"
    end

    it 'links with adjacent text' do
      doc = reference_filter("Iteration (#{reference}.)")

      expect(doc.to_html).to match(%r(\(<a.+>#{iteration.reference_link_text}</a>\.\)))
    end

    it 'ignores invalid iteration names' do
      exp = act = %(Iteration #{Iteration.reference_prefix}"#{iteration.name.reverse}")

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  shared_examples 'referencing a iteration in a link href' do
    let(:unquoted_reference) { "#{Iteration.reference_prefix}#{iteration.name}" }
    let(:link_reference) { %Q{<a href="#{unquoted_reference}">Iteration</a>} }

    before do
      iteration.update!(name: 'gfm')
    end

    it 'links to a valid reference' do
      doc = reference_filter("See #{link_reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.iteration_url(iteration)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Iteration (#{link_reference}.)")

      expect(doc.to_html).to match(%r(\(<a.+>Iteration</a>\.\)))
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Iteration #{link_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-iteration attribute' do
      doc = reference_filter("See #{link_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-iteration')
      expect(link.attr('data-iteration')).to eq iteration.id.to_s
    end
  end

  shared_examples 'linking to a iteration as the entire link' do
    let(:unquoted_reference) { "#{Iteration.reference_prefix}#{iteration.name}" }
    let(:link) { urls.iteration_url(iteration) }
    let(:link_reference) { %Q{<a href="#{link}">#{link}</a>} }

    it 'replaces the link text with the iteration reference' do
      doc = reference_filter("See #{link}")

      expect(doc.css('a').first.text).to eq(unquoted_reference)
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Iteration #{link_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-iteration attribute' do
      doc = reference_filter("See #{link_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-iteration')
      expect(link.attr('data-iteration')).to eq iteration.id.to_s
    end
  end

  shared_examples 'cross-project / cross-namespace complete reference' do
    let(:namespace) { create(:namespace) }
    let(:another_project) { create(:project, :public, namespace: namespace) }
    let(:iteration) { create(:iteration, project: another_project) }
    let(:reference) { "#{another_project.full_path}*iteration:#{iteration.iid}" }
    let!(:result) { reference_filter("See #{reference}") }

    it 'points to referenced project iteration page' do
      expect(result.css('a').first.attr('href'))
        .to eq(urls.project_iteration_url(another_project, iteration))
    end

    it 'link has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.css('a').first.text)
        .to eq("#{iteration.reference_link_text} in #{another_project.full_path}")
    end

    it 'has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.text)
        .to eq("See (#{iteration.reference_link_text} in #{another_project.full_path}.)")
    end

    it 'escapes the name attribute' do
      allow_next_instance_of(Iteration) do |instance|
        allow(instance).to receive(:title).and_return(%{"></a>whatever<a title="})
      end

      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.text)
        .to eq "#{iteration.reference_link_text} in #{another_project.full_path}"
    end
  end

  shared_examples 'cross project shorthand reference' do
    let(:namespace) { create(:namespace) }
    let(:project) { create(:project, :public, namespace: namespace) }
    let(:another_project) { create(:project, :public, namespace: namespace) }
    let(:iteration) { create(:iteration, project: another_project) }
    let(:reference) { "#{another_project.path}*iteration:#{iteration.iid}" }
    let!(:result) { reference_filter("See #{reference}") }

    it 'points to referenced project iteration page' do
      expect(result.css('a').first.attr('href')).to eq urls
                                                         .project_iteration_url(another_project, iteration)
    end

    it 'link has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.css('a').first.text)
        .to eq("#{iteration.reference_link_text} in #{another_project.path}")
    end

    it 'has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.text)
        .to eq("See (#{iteration.reference_link_text} in #{another_project.path}.)")
    end

    it 'escapes the name attribute' do
      allow_next_instance_of(Iteration) do |instance|
        allow(instance).to receive(:title).and_return(%{"></a>whatever<a title="})
      end

      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.text)
        .to eq "#{iteration.reference_link_text} in #{another_project.path}"
    end
  end

  shared_examples 'references with HTML entities' do
    before do
      iteration.update!(title: '&lt;html&gt;')
    end

    it 'links to a valid reference' do
      doc = reference_filter('See *iteration:"&lt;html&gt;"')

      expect(doc.css('a').first.attr('href')).to eq urls.iteration_url(iteration)
      expect(doc.text).to eq 'See <html>'
    end

    it 'ignores invalid iteration names and escapes entities' do
      act = %(Iteration *iteration:"&lt;non valid&gt;")

      expect(reference_filter(act).to_html).to eq act
    end
  end

  shared_context 'group iterations' do
    let(:reference) { iteration.to_reference(format: :name) }

    include_examples 'reference parsing'

    it_behaves_like 'String-based single-word references'
    it_behaves_like 'String-based multi-word references in quotes'
    it_behaves_like 'referencing a iteration in a link href'
    it_behaves_like 'references with HTML entities'
    it_behaves_like 'HTML text with references' do
      let(:resource) { iteration }
      let(:resource_text) { resource.title }
    end

    it 'does not support references by IID' do
      doc = reference_filter("See #{Iteration.reference_prefix}#{iteration.iid}")

      expect(doc.css('a')).to be_empty
    end

    it 'does not support references by link' do
      doc = reference_filter("See #{urls.iteration_url(iteration)}")

      expect(doc.css('a').first.text).to eq(urls.iteration_url(iteration))
    end

    it 'does not support cross-project references', :aggregate_failures do
      another_group = create(:group)
      another_project = create(:project, :public, group: group)
      project_reference = another_project.to_reference_base(project)
      input_text = "See #{project_reference}#{reference}"

      # we have to update iterations_cadence group first in order to avoid invalid record
      iteration.iterations_cadence.update_column(:group_id, another_group.id)
      iteration.update_column(:group_id, another_group.id)

      doc = reference_filter(input_text)

      expect(input_text).to match(Iteration.reference_pattern)
      expect(doc.css('a')).to be_empty
    end

    it 'supports parent group references' do
      # we have to update iterations_cadence group first in order to avoid invallid record
      iteration.iterations_cadence.update_column(:group_id, parent_group.id)
      iteration.update_column(:group_id, parent_group.id)

      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.text).to eq(iteration.reference_link_text)
    end
  end

  context 'group context' do
    let(:group) { create(:group) }
    let(:context) { { project: nil, group: group } }

    context 'when group iteration' do
      let(:group_iteration) { create(:iteration, title: 'group_iteration', group: group) }

      context 'for subgroups' do
        let(:sub_group) { create(:group, parent: group) }
        let(:sub_group_iteration) { create(:iteration, title: 'sub_group_iteration', group: sub_group) }

        it 'links to a valid reference of subgroup and group iterations' do
          [group_iteration, sub_group_iteration].each do |iteration|
            reference = "*iteration:#{iteration.title}"

            result = reference_filter("See #{reference}", { project: nil, group: sub_group })

            expect(result.css('a').first.attr('href')).to eq(urls.iteration_url(iteration))
          end
        end
      end

      context 'for private subgroups' do
        let(:sub_group) { create(:group, :private, parent: group) }
        let(:sub_group_iteration) { create(:iteration, title: 'sub_group_iteration', group: sub_group) }

        it 'links to a valid reference of subgroup and group iterations' do
          [group_iteration, sub_group_iteration].each do |iteration|
            reference = "*iteration:#{iteration.title}"

            result = reference_filter("See #{reference}", { project: nil, group: sub_group })

            expect(result.css('a').first.attr('href')).to eq(urls.iteration_url(iteration))
          end
        end
      end
    end
  end

  context 'when iteration is open' do
    context 'group iterations' do
      let(:iteration) { create(:iteration, group: group) }

      include_context 'group iterations'
    end
  end

  context 'when iteration is closed' do
    context 'group iterations' do
      let(:iteration) { create(:iteration, :closed, group: group) }

      include_context 'group iterations'
    end
  end
end
