class Category < ApplicationRecord
  has_many :categorizations, dependent: :destroy
  has_many :splats, through: :categorizations
end
