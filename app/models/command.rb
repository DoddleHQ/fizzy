class Command < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :user

  def title
    model_name.human
  end

  def execute
  end

  def undo
  end

  def undo!
    transaction do
      undo
      destroy
    end
  end

  def undoable?
    false
  end

  def needs_confirmation?
    false
  end

  private
    def redirect_to(...)
      Command::Result::Redirection.new(...)
    end
end
