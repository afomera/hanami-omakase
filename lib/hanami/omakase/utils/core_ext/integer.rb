# frozen_string_literal: true

# Extending Integer to provide time duration methods
# such as `seconds`, `minutes`, `hours`, `days`, and `weeks`.
# This allows for more readable time duration calculations.
# Example:
#   5.minutes  # => 300 (seconds)
#   2.hours    # => 7200 (seconds)
#   1.day      # => 86400 (seconds)
#   3.weeks    # => 1814400 (seconds)
class Integer
  def seconds
    self
  end
  alias_method :second, :seconds

  def minutes
    Hanami::Omakase::Utils::Duration.minutes(self)
  end
  alias_method :minute, :minutes

  def hours
    Hanami::Omakase::Utils::Duration.hours(self)
  end
  alias_method :hour, :hours

  def days
    Hanami::Omakase::Utils::Duration.days(self)
  end
  alias_method :day, :days

  def weeks
    Hanami::Omakase::Utils::Duration.weeks(self)
  end
  alias_method :week, :weeks

  def years
    Hanami::Omakase::Utils::Duration.years(self)
  end
  alias_method :year, :years
end
