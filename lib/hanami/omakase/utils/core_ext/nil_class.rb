# frozen_string_literal: true

class NilClass
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
