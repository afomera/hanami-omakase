# frozen_string_literal: true

require "hanami/utils/blank"

class String
  def blank?
    Hanami::Utils::Blank.blank?(self)
  end

  def present?
    !Hanami::Utils::Blank.blank?(self)
  end
end
