# frozen_string_literal: true

class TrueClass
  def blank?
    false
  end

  def present?
    true
  end

  def empty?
    false
  end
end
