require 'rails_helper'

RSpec.describe ClarkAgent::IrlCalculator do
  it 'computes the revised rent using the legal formula' do
    result = described_class.new(
      reference_rent: 850.00,
      base_irl:       136.27,
      current_irl:    142.06
    ).call

    expect(result[:revised_rent]).to be_within(0.05).of(886.13)
    expect(result[:increase]).to be_within(0.05).of(36.13)
    expect(result[:increase_pct]).to be_within(0.05).of(4.25)
  end

  it 'returns a no-op revision when both indices are equal' do
    result = described_class.new(
      reference_rent: 1000,
      base_irl:       140,
      current_irl:    140
    ).call

    expect(result[:revised_rent]).to eq(1000.0)
    expect(result[:increase]).to eq(0.0)
  end

  it 'raises ArgumentError when base_irl is zero or negative' do
    expect do
      described_class.new(reference_rent: 1000, base_irl: 0, current_irl: 140).call
    end.to raise_error(ArgumentError, /base_irl/)
  end
end
