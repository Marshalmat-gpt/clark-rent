# Calcule la révision annuelle d'un loyer indexé sur l'IRL
# (Indice de Référence des Loyers, INSEE).
#
# Formule légale (loi de 1989, art. 17-1) :
#   nouveau_loyer = loyer_reference * (irl_actuel / irl_reference)
module ClarkAgent
  class IrlCalculator
    attr_reader :reference_rent, :base_irl, :current_irl

    def initialize(reference_rent:, base_irl:, current_irl:)
      @reference_rent = reference_rent.to_d
      @base_irl       = base_irl.to_d
      @current_irl    = current_irl.to_d
    end

    def call
      raise ArgumentError, 'base_irl must be positive' if base_irl <= 0

      {
        reference_rent: reference_rent.to_f,
        base_irl: base_irl.to_f,
        current_irl: current_irl.to_f,
        revised_rent: revised_rent.to_f,
        increase: increase.to_f,
        increase_pct: increase_pct.to_f
      }
    end

    private

    def revised_rent
      @revised_rent ||= (reference_rent * current_irl / base_irl).round(2)
    end

    def increase
      (revised_rent - reference_rent).round(2)
    end

    def increase_pct
      ((current_irl - base_irl) / base_irl * 100).round(2)
    end
  end
end
