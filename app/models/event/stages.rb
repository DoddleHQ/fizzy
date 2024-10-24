module Event::Stages
  extend ActiveSupport::Concern

  included do
    store_accessor :particulars, :stage_id, :stage_name
  end
end
