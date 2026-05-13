require 'rails_helper'

RSpec.describe ClarkAgent::ToolRegistry do
  describe '.tool_specs' do
    subject(:specs) { described_class.tool_specs }

    it 'returns 10 specs' do
      expect(specs.length).to eq(10)
    end

    it 'includes all tenant tools' do
      names = specs.map { |s| s[:name] }
      expect(names).to include('get_my_lease', 'get_payment_history', 'create_ticket',
                               'get_ticket_status', 'get_document')
    end

    it 'includes all owner tools' do
      names = specs.map { |s| s[:name] }
      expect(names).to include('list_properties', 'get_property', 'list_applications',
                               'calculate_irl_revision', 'generate_rent_receipt')
    end

    it 'each spec has name, description, and input_schema' do
      specs.each do |spec|
        expect(spec).to have_key(:name)
        expect(spec).to have_key(:description)
        expect(spec).to have_key(:input_schema)
      end
    end

    it 'has no handler lambdas (dispatch is ToolExecutor responsibility)' do
      specs.each do |spec|
        expect(spec).not_to have_key(:handler)
      end
    end
  end
end
