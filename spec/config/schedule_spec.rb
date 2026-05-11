require 'rails_helper'
require 'yaml'

RSpec.describe 'config/schedule.yml' do
  let(:path)     { Rails.root.join('config/schedule.yml') }
  let(:schedule) { YAML.load_file(path) }

  it 'exists' do
    expect(path).to exist
  end

  it 'declares the two cron entries with valid classes and cron strings' do
    expect(schedule.keys).to contain_exactly('generate_monthly_rent_payments', 'ticket_sla_escalation')

    schedule.each_value do |entry|
      expect(entry['cron']).to match(%r{\A[\d \*/,-]+\z})
      klass = entry['class'].constantize
      expect(klass.ancestors).to include(ApplicationJob)
    end
  end
end
