# frozen_string_literal: true

class FalseClass
  def blank?
    true
  end

  def present?
    false
  end

  def empty?
    true
  end
end
