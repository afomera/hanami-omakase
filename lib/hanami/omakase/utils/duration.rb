# frozen_string_literal: true

module Hanami
  module Omakase
    module Utils
      module Duration
        SECONDS_IN_MINUTE = 60
        MINUTES_IN_HOUR   = 60
        HOURS_IN_DAY      = 24
        SECONDS_IN_HOUR = SECONDS_IN_MINUTE * MINUTES_IN_HOUR
        SECONDS_IN_DAY = SECONDS_IN_HOUR * HOURS_IN_DAY

        class << self
          def seconds(value)
            value
          end

          def minutes(value)
            value * SECONDS_IN_MINUTE
          end

          def hours(value)
            value * SECONDS_IN_HOUR
          end

          def days(value)
            value * SECONDS_IN_DAY
          end

          def weeks(value)
            value * SECONDS_IN_DAY * 7
          end

          def years(value)
            value * SECONDS_IN_DAY * 365
          end
        end
      end
    end
  end
end
