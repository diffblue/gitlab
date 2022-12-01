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

  shared_context 'group iterations' do
    let(:reference) { iteration.to_reference(format: :name) }

    include_examples 'reference parsing'

    it_behaves_like 'String-based single-word references'
    it_behaves_like 'String-based multi-word references in quotes'
    it_behaves_like 'referencing a iteration in a link href'

    it_behaves_like 'Integer-based references' do
      let(:reference) { iteration.to_reference(format: :id) }
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
      # we have to update iterations_cadence group first in order to avoid an invalid record
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
      let(:iteration) { create(:iteration, :with_title, group: group) }

      include_context 'group iterations'
    end
  end

  context 'when iteration is closed' do
    context 'group iterations' do
      let(:iteration) { create(:iteration, :with_title, :closed, group: group) }

      include_context 'group iterations'
    end
  end

  context 'checking N+1' do
    let_it_be(:group) { create(:group) }
    let_it_be(:group2) { create(:group, parent: group) }
    let_it_be(:iteration) { create(:iteration, :with_title, group: group) }
    let_it_be(:iteration_reference) { iteration.to_reference(format: :name) }
    let_it_be(:iteration2) { create(:iteration, :with_title, group: group) }
    let_it_be(:iteration2_reference) { iteration2.to_reference(format: :id) }
    let_it_be(:iteration3) { create(:iteration, :with_title, group: group2) }
    let_it_be(:iteration3_reference) { iteration3.to_reference(format: :name) }

    it 'does not have N+1 per multiple references per group', :use_sql_query_cache, :aggregate_failures do
      max_count = 4
      markdown = iteration_reference.to_s

      # warm the cache
      reference_filter(markdown)

      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(max_count)

      markdown = "#{iteration_reference} *iteration:\"Not Found\" *iteration:\"Not Found2\" #{iteration2_reference}"

      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(max_count)
    end

    it 'has N+1 for multiple unique group references', :use_sql_query_cache do
      markdown = iteration_reference.to_s
      max_count = 4

      # warm the cache
      reference_filter(markdown, { project: nil, group: group2 })

      expect do
        reference_filter(markdown, { project: nil, group: group2 })
      end.not_to exceed_all_query_limit(max_count)

      # Since we're not batching iteration queries across groups,
      # queries increase when a new group is referenced.
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/330359
      markdown = "#{iteration_reference} #{iteration2_reference} #{iteration3_reference}"
      max_count += 1

      # Feature flag check for iteration_cadences fetches the root ancestor for a group
      # so we need to add another query here. This should be removed when the feature flag is removed.
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/354878
      max_count += 1

      expect do
        reference_filter(markdown, { project: nil, group: group2 })
      end.not_to exceed_all_query_limit(max_count)
    end
  end
end
