# frozen_string_literal: true

module Analytics
  module Forecasting
    # Picks best smoothing params for algorithm implemented in HoltWinters class
    class HoltWintersOptimizer
      attr_reader :time_series, :model_class

      SEASON_LENGTH = 7 # First metrics will be weekly so we hardcode it for now.
      STARTING_POINT = { alpha: 0.5, beta: 0.5, gamma: 0.5 }.freeze

      def self.model_for(*args, **params)
        new(*args, **params).model
      end

      def initialize(time_series, model_class: HoltWinters)
        @time_series = time_series
        @model_class = model_class
      end

      # Evaluate up to 162 models to find the best fit params.
      def model
        @model ||= begin
          current_model = model_class.new(time_series, **STARTING_POINT.merge(season: SEASON_LENGTH))
          current_step = 0.5

          while current_step > 0.01 # that gives us 6 iterations since 1/64 is ~0.015
            candidates = generate_combinations(current_model, current_step)

            models = candidates.map do |(alpha, beta, gamma)|
              model_class.new(time_series, alpha: alpha, beta: beta, gamma: gamma, season: SEASON_LENGTH)
            end

            current_model = models.max_by(&:r2_score)
            current_step /= 2.0
          end

          current_model
        end
      end

      private

      def generate_combinations(current_model, step)
        alpha = current_model.alpha
        beta = current_model.beta
        gamma = current_model.gamma

        alphas = [alpha - step, alpha, alpha + step].select { |v| v.between?(0, 1) }
        betas = [beta - step, beta, beta + step].select { |v| v.between?(0, 1) }
        gammas = [gamma - step, gamma, gamma + step].select { |v| v.between?(0, 1) }

        alphas.product(betas, gammas)
      end
    end
  end
end
